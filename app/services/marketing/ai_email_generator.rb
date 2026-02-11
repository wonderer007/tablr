module Marketing
  class AiEmailGenerator
    def initialize(company:, model: Marketing::Email::DEFAULT_MODEL)
      @company = company
      @business = company.business
      @model = model
      @provider = Marketing::Email::MODELS[model] || :openai
    end

    def call
      return { error: "No business linked to company" } unless business.present?
      return { error: "Business analysis not completed" } unless business.first_inference_completed?

      report_data = fetch_business_report_data
      generated_content = generate_email(report_data)

      {
        subject: random_subject,
        body: extract_body(generated_content)
      }
    end

    private

    attr_reader :company, :business, :model, :provider

    def fetch_business_report_data
      ActsAsTenant.with_tenant(business) do
        reviews = business.reviews.where(processed: true)

        {
          business_name: business.name,
          rating: business.rating,
          total_reviews: reviews.count,
          top_complaints: fetch_top_items(Complain, reviews, 5),
          top_suggestions: fetch_top_items(Suggestion, reviews, 5),
          top_complaint_categories: fetch_category_counts(Complain, reviews, 3),
          top_suggestion_categories: fetch_category_counts(Suggestion, reviews, 3)
        }
      end
    end

    def fetch_top_items(model_class, reviews, limit)
      items_by_category = model_class.where(review_id: reviews.select(:id))
                               .includes(:category)
                               .order(severity: :desc)
                               .group_by(&:category_id)

      return [] if items_by_category.empty?

      result = []
      category_indices = items_by_category.transform_values { 0 }

      while result.size < limit
        added_any = false

        items_by_category.each do |category_id, items|
          break if result.size >= limit

          index = category_indices[category_id]
          if index < items.size
            result << items[index]
            category_indices[category_id] += 1
            added_any = true
          end
        end

        break unless added_any
      end

      result.sort_by { |item| -item.severity.to_i }.map do |item|
        {
          text: item.text,
          severity: item.severity,
          category: item.category&.name
        }
      end
    end

    def fetch_category_counts(model_class, reviews, limit)
      model_class.where(review_id: reviews.select(:id))
           .joins(:category)
           .group('categories.name')
           .order('count_all DESC')
           .limit(limit)
           .count
    end

    def generate_email(report_data)
      case provider
      when :openai
        generate_via_openai(report_data)
      when :gemini
        generate_via_gemini(report_data)
      else
        generate_via_openai(report_data)
      end
    end

    # GPT-5 family models are reasoning models that don't support the temperature parameter.
    # They use reasoning_effort instead. Only gpt-5.2 supports temperature when reasoning_effort is "none".
    GPT5_REASONING_MODELS = %w[gpt-5-nano gpt-5-mini].freeze

    def generate_via_openai(report_data)
      params = {
        model: model,
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: user_prompt(report_data) }
        ]
      }

      if GPT5_REASONING_MODELS.include?(model)
        params[:reasoning_effort] = 'medium'
      elsif model.start_with?('gpt-5')
        params[:reasoning_effort] = 'none'
        params[:temperature] = 0.7
      else
        params[:temperature] = 0.7
      end

      openai_client.chat(parameters: params).dig('choices', 0, 'message', 'content')
    end

    def generate_via_gemini(report_data)
      result = gemini_client.generate_content({
        system_instruction: { role: 'user', parts: { text: system_prompt } },
        contents: { role: 'user', parts: { text: user_prompt(report_data) } },
        generation_config: { temperature: 0.7 }
      })

      # Gemini 2.5 thinking models may return thought parts before the answer.
      # Find the last non-thought text part, which contains the actual response.
      parts = result.dig('candidates', 0, 'content', 'parts') || []
      text_part = parts.reverse.find { |p| p['text'] && !p['thought'] }
      text_part&.dig('text')
    end

    def system_prompt
      <<~PROMPT
        You write helpful outreach emails on behalf of Tablr.io, a platform that analyzes customer feedback for businesses. You have analyzed their reviews and want to share genuine insights.

        Tone: warm, professional, conversational. Write like a real colleague, not a marketer.

        Follow this exact structure for every email:

        1. Greeting: "Hi {{RECIPIENT_NAME}},"
        2. Opening (1 sentence, under 25 words): mention you used Tablr.io to analyze their recent reviews and found patterns worth sharing.
        3. Complaint transition (1 sentence): lead into the patterns, e.g. "Here are some patterns I noticed:"
        4. Complaints (2-3 bullet points): each names a theme and includes a brief customer quote.
        5. Suggestion transition (1 sentence): lead into suggestions, e.g. "Customers also had a few suggestions:"
        6. Suggestions (2-3 bullet points): each is a specific, actionable suggestion from customers.
        7. Soft CTA (1 sentence): offer to share the full analysis report. No pressure.
        8. Sign-off: Best,<br/>Haider Ali<br/>Founder, Tablr.io

        Rules:
        - Body under 150 words (excluding signature and unsubscribe)
        - Always use bullet points for complaints and suggestions
        - Keep each sentence under 25 words
        - Vary wording naturally across sections — do not repeat phrases
        - Never use: free, guaranteed, act now, exclusive, unlock, boost, skyrocket, game-changer, limited time, click here, buy now, don't miss out, congratulations
        - No ALL CAPS, no excessive punctuation (!!, ??, $$)

        HTML output:
        - Use <p> for paragraphs, <ul><li> for bullet lists
        - No <strong>, <b>, <em>, <i> tags or inline styles in body content
        - End with: <p style="font-size: 12px; color: #666; margin-top: 20px;">Don't want to receive these emails? {{UNSUBSCRIBE_LINK}}</p>
      PROMPT
    end

    def user_prompt(data)
      complaints_text = format_items(data[:top_complaints], "complaint")
      suggestions_text = format_items(data[:top_suggestions], "suggestion")
      complaint_categories = format_categories(data[:top_complaint_categories])
      suggestion_categories = format_categories(data[:top_suggestion_categories])

      <<~PROMPT
        Write an email for the owner of #{data[:business_name]}.

        #{data[:total_reviews]} reviews analyzed | Overall rating: #{data[:rating] || 'N/A'}

        Complaint categories:
        #{complaint_categories}

        Customer complaints:
        #{complaints_text}

        Suggestion categories:
        #{suggestion_categories}

        Customer suggestions:
        #{suggestions_text}

        Pick the 2-3 most impactful complaints and 2-3 most actionable suggestions. Include customer quotes. Follow the structure from your instructions.
      PROMPT
    end

    def format_items(items, type)
      return "No #{type}s found" if items.empty?

      items.first(5).map.with_index do |item, i|
        "#{i + 1}. [#{item[:category]}] \"#{item[:text]}\""
      end.join("\n")
    end

    def format_categories(categories)
      return "No data" if categories.empty?

      categories.map { |name, count| "- #{name}: #{count} mentions" }.join("\n")
    end

    SUBJECT_TEMPLATES = [
      'A few insights from %{business_name} recent customer reviews',
      'Insights from customer feedback for %{business_name}',
      'Customer feedback insights for %{business_name}'
    ].freeze

    def random_subject
      SUBJECT_TEMPLATES.sample % { business_name: business.name }
    end

    def extract_body(content)
      return default_body unless content.present?

      body = content.strip

      # Strip markdown code fences (```html ... ``` or ``` ... ```)
      if body.match?(/\A```/)
        body = body.sub(/\A```\w*\s*\n?/, '').sub(/\n?```\s*\z/, '')
      end

      body.strip
    end

    def default_body
      <<~HTML
        <p>Hi {{RECIPIENT_NAME}},</p>
        <p>I recently analyzed customer reviews for your business and found some interesting insights I thought you might find valuable.</p>
        <p>Would you be interested in seeing the full analysis?</p>
        <p>Best,<br/>Haider Ali<br/>Tablr.io</p>
        <p style="font-size: 12px; color: #666; margin-top: 20px;">Don't want to receive these emails? {{UNSUBSCRIBE_LINK}}</p>
      HTML
    end

    def openai_client
      @openai_client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
    end

    def gemini_client
      @gemini_client ||= Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: ENV.fetch('GEMINI_API_KEY'),
          version: 'v1beta'
        },
        options: { model: model, server_sent_events: false }
      )
    end
  end
end
