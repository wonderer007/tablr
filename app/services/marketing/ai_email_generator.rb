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
          food_rating: business.food_rating,
          service_rating: business.service_rating,
          atmosphere_rating: business.atmosphere_rating,
          total_reviews: reviews.count,
          total_complaints: Complain.where(review_id: reviews.select(:id)).count,
          total_suggestions: Suggestion.where(review_id: reviews.select(:id)).count,
          top_complaints: fetch_top_items(Complain, reviews, 10),
          top_suggestions: fetch_top_items(Suggestion, reviews, 10),
          top_complaint_categories: fetch_category_counts(Complain, reviews, 5),
          top_suggestion_categories: fetch_category_counts(Suggestion, reviews, 5)
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
        You are a helpful consultant who genuinely wants to help business owners improve their customer experience.
        You have analyzed their customer reviews and want to share valuable insights with them.

        Your tone should be:
        - Warm and professional, like a helpful colleague
        - Focused on sharing insights, not selling anything
        - Empathetic to the challenges of running a business
        - Specific and actionable with the feedback you share

        Do NOT:
        - Use sales language or urgency tactics
        - Promise revenue increases or ROI
        - Push for demos or meetings aggressively
        - Use phrases like "unlock", "boost", "skyrocket", "game-changer", "exclusive", "act now", "limited time", "free", "guaranteed", "congratulations"
        - Use excessive exclamation marks or ALL CAPS words
        - Use spam-trigger phrases like "click here", "buy now", "order now", "don't miss out", "once in a lifetime", "winner", "no obligation"
        - Use deceptive or misleading language
        - Use excessive punctuation (!!!, ???, $$$)

        DO:
        - Share 2-3 specific customer insights that would be genuinely useful
        - Mention patterns you noticed in the feedback
        - Offer to share more details full analysis report if they're interested
        - Keep the email concise (under 150 words for the body)
        - Keep sentences short and concise. Wherever possible use bullet points and references from complaints and suggestions to make it more engaging and persuasive.
        - Write naturally and conversationally, like a real person would
        - Avoid repeating the same word or phrase multiple times
        - Keep the language simple and straightforward

        Output format:
        Return the email body in HTML format directly (no subject line needed).

        For the HTML body:
        - Start with a greeting using the placeholder {{RECIPIENT_NAME}} like: <p>Hi {{RECIPIENT_NAME}},</p>
        - Use <p> tags for paragraphs
        - Keep formatting minimal and clean — avoid excessive HTML tags, inline styles, or complex nesting
        - Do NOT use <strong>, <bold>, <b>, <em>, or <i> tags
        - Do NOT use colored text, font-size changes, or other inline styling in the body content
        - End with a simple signature: Best,<br/>Haider Ali<br/>Tablr.io
        - Include an unsubscribe placeholder at the end: <p style="font-size: 12px; color: #666; margin-top: 20px;">Don't want to receive these emails? {{UNSUBSCRIBE_LINK}}</p>
      PROMPT
    end

    def user_prompt(data)
      complaints_text = format_items(data[:top_complaints], "complaint")
      suggestions_text = format_items(data[:top_suggestions], "suggestion")
      complaint_categories = format_categories(data[:top_complaint_categories])
      suggestion_categories = format_categories(data[:top_suggestion_categories])

      <<~PROMPT
        Please write a helpful email to the owner of #{data[:company_name]}.

        Business Details:
        - Rating: #{data[:rating] || 'N/A'} stars
        - Food rating: #{data[:food_rating] || 'N/A'}
        - Service rating: #{data[:service_rating] || 'N/A'}
        - Atmosphere rating: #{data[:atmosphere_rating] || 'N/A'}
        - Reviews analyzed: #{data[:total_reviews]}
        - Total complaints found: #{data[:total_complaints]}
        - Total suggestions found: #{data[:total_suggestions]}

        Top Complaint Categories:
        #{complaint_categories}

        Top Complaints from Customers:
        #{complaints_text}

        Top Suggestion Categories:
        #{suggestion_categories}

        Top Suggestions from Customers:
        #{suggestions_text}

        Write the email body (HTML only, no subject line) that:
        1. Start with like: Hi {{RECIPIENT_NAME}},
        2. Introduce tablr.io and how it can help businesses improve their customer experience briefly.
        3. Acknowledges their business briefly
        4. Share complaint patterns and if possible references from complaints to make it more engaging and persuasive.
        5. Share suggestions from customers and if possible references from suggestions to make it more engaging and persuasive.
        6. Keep lines short and concise.
        7. Offers to share the full analysis report if they're interested (soft CTA)

        Important guidelines:
        - Keep it genuine and helpful, not salesy.
        - Write like a real person — natural, conversational tone.
        - Avoid spam-trigger words (free, guaranteed, act now, exclusive, etc.).
        - No ALL CAPS words, excessive punctuation, or exclamation marks.
        - Keep HTML minimal — just <p> tags and <br/> where needed, no extra styling.
      PROMPT
    end

    def format_items(items, type)
      return "No #{type}s found" if items.empty?

      items.first(10).map.with_index do |item, i|
        "#{i + 1}. [#{item[:category]}] \"#{item[:text]}\""
      end.join("\n")
    end

    def format_categories(categories)
      return "No data" if categories.empty?

      categories.map { |name, count| "- #{name}: #{count} mentions" }.join("\n")
    end

    SUBJECT_TEMPLATES = [
      'A few insights from your recent customer reviews',
      'Insights from customer feedback for %{business_name}',
      'Customer feedback insights for %{business_name}'
    ].freeze

    def random_subject
      SUBJECT_TEMPLATES.sample % { business_name: business.name }
    end

    def extract_body(content)
      return default_body unless content.present?

      # Strip BODY: prefix if the model still includes it
      match = content.match(/BODY:\s*(.+)/im)
      body = match ? match[1].strip : content.strip

      body
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
