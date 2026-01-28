require 'openai'
require 'tiktoken_ruby'

class Ai::ReviewInference < ApplicationService
  attr_reader :business_id, :review_ids

  BATCH_LIMIT = 50

  def initialize(business_id:, review_ids:)
    @business_id = business_id
    @review_ids = review_ids
  end

  def call
    return if reviews.empty?

    parsed_response = inference_response
    # Validate response count matches input count
    if parsed_response.size != reviews.size
      Rails.logger.error("[ReviewInference] Mismatch: expected #{reviews.size} responses, got #{parsed_response.size}")
      raise "AI returned #{parsed_response.size} responses for #{reviews.size} reviews"
    end

    parsed_response.each_with_index do |inference, index|
      review = business.reviews.find(inference['review_id'])

      inference.fetch('complains', {}).each do |category_name, items|
        name = category_name.downcase.split.map(&:capitalize).join(' ')
        category = Category.find_or_create_by(name: name)
        items.each do |item|
          review.complains.create(category: category, text: item['text'], severity: item['severity'])
        end
      end

      inference.fetch('suggestions', {}).each do |category_name, items|
        name = category_name.downcase.split.map(&:capitalize).join(' ')
        category = Category.find_or_create_by(name: name)
        items.each do |item|
          review.suggestions.create(category: category, text: item['text'], severity: item['severity'])
        end
      end

      review.update(processed: true)
    end

    business.inference_requests.create(
      response: response,
      input_token_count: input_token_count,
      output_token_count: output_token_count
    )
  end

  private

  def response
    @response ||= client.chat(
      parameters: {
        model: model,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: "You are an expert at analyzing customer reviews. Your task is to extract complaints and suggestions from a batch of reviews for any type of business and return structured JSON output for each review, in the same order and same number of reviews as the input (#{reviews.size})."
          },
          {
            role: "user",
            content: <<~PROMPT
              ### INSTRUCTIONS:
              1. For each review, extract complaints and suggestions grouped by relevant category
              2. Infer categories from the review content (e.g., #{categories.join(',')})
              3. For each complaint and suggestion, assign a severity score between 1 and 10. 1 is the lowest severity and 10 is the highest severity
              4. Complaints and suggestions MUST be arrays of plain strings (human-readable text) for each category key
              5. If a review has no complaints or suggestions, return empty objects for those fields
              6. IMPORTANT: You MUST return EXACTLY #{reviews.size} objects in the array, one for each numbered review below. Do not split or merge reviews
              7. Use lowercase category names.

              ### INPUT (#{reviews.size} reviews):
              #{numbered_reviews}

              ### OUTPUT FORMAT (JSON array with EXACTLY #{reviews.size} objects):
              #{output_sample.to_json}
            PROMPT
          }
        ]
      }
    )
  end

  def model
    @model ||= business.plan.to_sym == :pro ? 'gpt-4o' : 'gpt-4o-mini'
  end

  def categories
    @categories ||= business.type.to_sym == :restaurant ? RESTAURANT_CATEGORIES : business.type.to_sym == :hotel ? HOTEL_CATEGORIES : OTHERS_CATEGORIES
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end

  def reviews
    @reviews ||= business.reviews.where(id: review_ids, processed: false)
                              .where.not(text: nil)
                              .limit(BATCH_LIMIT)
                              .select(:id, :text, :processed, :business_id)
                              .reject { |review| review.text.split.size > 800 }
  end

  def business
    @business ||= Business.find(business_id)
  end

  def numbered_reviews
    reviews.each_with_index.map do |review, index|
      "[Review ID: #{review.id}] #{review.text}"
    end.join("\n\n")
  end

  def output_sample
    [
      {
        "review_id": 1,
        "complains": {
          "service": [{"text": "service was slow", "severity": 5}],
          "cleanliness": [{"text": "place was not very clean", "severity": 3}]
        },
        "suggestions": {
          "reservation": [{"text": "booking a table in advance", "severity": 7}]
        }
      }
    ]
  end

  def inference_response
    raw_output = response.dig('choices', 0, 'message', 'content')
    cleaned_output = raw_output.gsub(/```json\n|\n```/, '')
    JSON.parse(cleaned_output)
  end

  def encoder
    @encoder ||= Tiktoken.encoding_for_model(model)
  end

  def input_token_count
    system_message = "You are an expert at analyzing customer reviews. Your task is to extract complaints and suggestions from a batch of reviews for any type of business and return structured JSON output for each review, in the same order and same number of reviews as the input (#{reviews.size})."
    user_message = <<~PROMPT
      ### INSTRUCTIONS:
      1. For each review, extract complaints and suggestions grouped by relevant category
      2. Infer categories from the review content (e.g., #{categories.join(',')})
      3. For each complaint and suggestion, assign a severity score between 1 and 10. 1 is the lowest severity and 10 is the highest severity
      4. Complaints and suggestions MUST be arrays of plain strings (human-readable text) for each category key
      5. If a review has no complaints or suggestions, return empty objects for those fields
      6. IMPORTANT: You MUST return EXACTLY #{reviews.size} objects in the array, one for each numbered review below. Do not split or merge reviews
      7. Use lowercase category names.

      ### INPUT (#{reviews.size} reviews):
      #{numbered_reviews}

      ### OUTPUT FORMAT (JSON array with EXACTLY #{reviews.size} objects):
      #{output_sample.to_json}
    PROMPT

    encoder.encode(system_message).length + encoder.encode(user_message).length
  end

  def output_token_count
    output_text = response.dig('choices', 0, 'message', 'content') || ''
    encoder.encode(output_text).length
  end
end
