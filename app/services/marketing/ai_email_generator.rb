module Marketing
  class AiEmailGenerator
    def initialize(company:)
      @company = company
      @business = company.business
    end

    def call
      return { error: "No business linked to company" } unless business.present?
      return { error: "Business analysis not completed" } unless business.first_inference_completed?

      report_data = fetch_business_report_data
      generated_content = generate_email(report_data)

      {
        subject: extract_subject(generated_content),
        body: extract_body(generated_content)
      }
    end

    private

    attr_reader :company, :business

    def fetch_business_report_data
      ActsAsTenant.with_tenant(business) do
        reviews = business.reviews.where(processed: true)

        {
          company_name: company.name,
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

    def fetch_top_items(model, reviews, limit)
      items_by_category = model.where(review_id: reviews.select(:id))
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

    def fetch_category_counts(model, reviews, limit)
      model.where(review_id: reviews.select(:id))
           .joins(:category)
           .group('categories.name')
           .order('count_all DESC')
           .limit(limit)
           .count
    end

    def generate_email(report_data)
      client.chat(
        parameters: {
          model: 'gpt-4o-mini',
          temperature: 0.7,
          messages: build_prompt(report_data)
        }
      ).dig('choices', 0, 'message', 'content')
    end

    def build_prompt(report_data)
      [
        { role: 'system', content: system_prompt },
        { role: 'user', content: user_prompt(report_data) }
      ]
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
        - Use phrases like "unlock", "boost", "skyrocket", "game-changer"
        - Use excessive exclamation marks

        DO:
        - Share 2-3 specific customer insights that would be genuinely useful
        - Mention patterns you noticed in the feedback
        - Offer to share more details full analysis report if they're interested
        - Keep the email concise (under 150 words for the body)
        - Keep sentences short and concise. Whereever possible use bullet points and references from complains and suggestions to make it more engaging and persuasive.

        Output format:
        Return the email in this exact format:
        SUBJECT: [Your subject line here]
        BODY:
        [Your email body in HTML format here]

        For the HTML body:
        - Start with a greeting using the placeholder {{RECIPIENT_NAME}} like: <p>Hi {{RECIPIENT_NAME}},</p>
        - Use <p> tags for paragraphs
        - Keep formatting minimal and clean
        - Do NOT use <strong>, <bold>, <b>, <em>, or <i> tags
        - End with a simple signature: Best,<br/>Haider Ali<br/>Founder, Tablr.io
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

        Write an email that:
        1. Acknowledges their business briefly
        2. Mention Google Map reviews as source of customer feedback
        3. Share complains patterns and if possible references from complains to make it more engaging and persuasive.
        4. Share suggestions from customers and if possible references from suggestions to make it more engaging and persuasive.
        5. Keep sentences short and concise.
        6. Offers to share the full analysis report if they're interested (soft CTA)

        Keep it genuine and helpful, not salesy.
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

    def extract_subject(content)
      return default_subject unless content.present?

      match = content.match(/SUBJECT:\s*(.+?)(?:\n|BODY:)/i)
      match ? match[1].strip : default_subject
    end

    def extract_body(content)
      return default_body unless content.present?

      match = content.match(/BODY:\s*(.+)/im)
      body = match ? match[1].strip : content

      # Replace unsubscribe placeholder - will be replaced with actual link when sending
      body
    end

    def default_subject
      company_name = company.name.to_s.split.map(&:titleize).join(" ")
      "Some customer feedback about #{company_name}"
    end

    def default_body
      <<~HTML
        <p>Hi {{RECIPIENT_NAME}},</p>
        <p>I recently analyzed customer reviews for your business and found some interesting insights I thought you might find valuable.</p>
        <p>Would you be interested in seeing the full analysis?</p>
        <p>Best,<br/>Haider Ali<br/>Founder, Tablr</p>
        <p style="font-size: 12px; color: #666; margin-top: 20px;">Don't want to receive these emails? {{UNSUBSCRIBE_LINK}}</p>
      HTML
    end

    def client
      @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
    end
  end
end
