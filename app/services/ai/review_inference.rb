require 'openai'

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
        category = Category.find_or_create_by(name: category_name)
        items.each do |item|
          review.complains.create(category: category, text: item)
        end
      end

      inference.fetch('suggestions', {}).each do |category_name, items|
        category = Category.find_or_create_by(name: category_name)
        items.each do |item|
          review.suggestions.create(category: category, text: item)
        end
      end

      review.update(processed: true)
    end

    business.inference_responses.create(response: response)
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
              1. For each review, extract complaints and suggestions grouped by relevant category.
              2. Infer categories from the review content (e.g., service, pricing, quality, staff, location, wait time, cleanliness, product, experience, communication, etc.).
              3. Complaints and suggestions MUST be arrays of plain strings (human-readable text) for each category key.
              4. If a review has no complaints or suggestions, return empty objects for those fields.
              5. Use lowercase category names.
              6. IMPORTANT: You MUST return EXACTLY #{reviews.size} objects in the array, one for each numbered review below. Do not split or merge reviews.

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
          "service": ["service was slow"],
          "cleanliness": ["place was not very clean"]
        },
        "suggestions": {
          "reservation": ["booking a table in advance"]
        }
      }
    ]
  end

  def inference_response
    raw_output = response.dig('choices', 0, 'message', 'content')
    cleaned_output = raw_output.gsub(/```json\n|\n```/, '')
    JSON.parse(cleaned_output)
  end
end
