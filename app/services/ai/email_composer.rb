require 'openai'

class Ai::EmailComposer < ApplicationService
  attr_reader :place_id, :company_id, :positive_keywords, :negative_keywords, :complaint_summary, :suggestion_summary, :company_name

  def initialize(place_id:, company_id:, positive_keywords:, negative_keywords:, complaint_summary:, suggestion_summary:, company_name:)
    @place_id = place_id
    @company_id = company_id
    @positive_keywords = positive_keywords
    @negative_keywords = negative_keywords
    @complaint_summary = complaint_summary
    @suggestion_summary = suggestion_summary
    @company_name = company_name
  end

  def call
    return generate_email_content if place.test == true && place.status == :created

    company.update(ai_generated_content: generate_email_content)
    company.ai_generated_content
  end

  def place
    @place ||= Place.find(place_id)
  end

  def company
    @company ||= Marketing::Company.find(company_id)
  end

  private

  def generate_email_content
    response = client.chat(
      parameters: {
        model: 'gpt-4o',
        temperature: 0.7,
        max_tokens: 500,
        messages: [
          {
            role: "system",
            content: "You are a professional email copywriter specializing in review analysis software sales. Write compelling, personalized email introductions that highlight key insights from customer reviews to help businesses improve their operations."
          },
          {
            role: "user",
            content: email_prompt
          }
        ]
      }
    )

    response.dig('choices', 0, 'message', 'content').strip
  end

  def email_prompt
    <<~PROMPT
    Write a compelling 2-paragraph email introduction for a business owner about their review analysis. The email should:

    1. Start with an engaging hook about analyzing their recent reviews
    2. Highlight what customers love most (positive themes)
    3. Mention key areas for improvement (negative themes/complaints)
    4. Keep it professional but conversational
    5. Focus on helping them improve return rates and revenue

    Company Name: #{company_name}

    Positive Keywords (most mentioned strengths): #{format_keywords(positive_keywords)}
    Negative Keywords (most mentioned issues): #{format_keywords(negative_keywords)}
    Top Complaints: #{format_complaints(complaint_summary)}
    Top Suggestions: #{format_suggestions(suggestion_summary)}

    Write exactly 2 paragraphs. First paragraph: Introduction and positive insights. Second paragraph: Key challenges and call to action setup.
    PROMPT
  end

  def format_keywords(keywords)
    return "None identified" if keywords.blank?

    keywords.first(5).map { |kw| kw[:name] }.join(", ")
  end

  def format_complaints(summary)
    return "None identified" if summary.blank? || summary[:top].blank?

    summary[:top].first(3).map { |item| item[:text] }.join(", ")
  end

  def format_suggestions(summary)
    return "None identified" if summary.blank? || summary[:top].blank?

    summary[:top].first(3).map { |item| item[:text] }.join(", ")
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end
end
