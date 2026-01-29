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
            content: "You are an expert at analyzing customer reviews for a #{business_type}. Extract complaints and suggestions from reviews and return structured JSON output."
          },
          {
            role: "user",
            content: <<~PROMPT
              Analyze the following #{reviews.size} reviews and extract complaints and suggestions from each one.

              ## TASK
              For each review:
              1. Extract all COMPLAINTS (negative feedback, issues, problems mentioned)
              2. Extract all SUGGESTIONS (recommendations, improvements, wishes mentioned)
              3. Assign each complaint/suggestion to a CATEGORY
              4. Assign a SEVERITY score (1-10) based on impact: 1 = minor, 10 = critical

              ## CATEGORIES
              Prefer these categories when applicable: #{categories.join(', ')}
              If a complaint/suggestion doesn't fit these categories, create a descriptive category name.

              ## REVIEWS
              #{numbered_reviews}

              ## OUTPUT REQUIREMENTS
              - Return a JSON array with EXACTLY #{reviews.size} objects (one for each input review)
              - CRITICAL: Include the exact "review_id" from the input (the number after "Review ID:")
              - Group complaints under "complains" by category
              - Group suggestions under "suggestions" by category
              - Each item must have "text" and "severity" (1-10)
              - if a review has no complains or suggestions then don't include it in the output and only return the review_id in object

              ## EXAMPLE OUTPUT FORMAT
              #{output_sample.to_json}

              Return ONLY the JSON array, no additional text.
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
        "review_id": 123,
        "complains": {
          "service": [
            { "text": "waited 30 minutes for our order", "severity": 6 }
          ],
          "cleanliness": [
            { "text": "tables were sticky", "severity": 4 }
          ]
        },
        "suggestions": {
          "service": [
            { "text": "hire more staff during peak hours", "severity": 5 }
          ]
        }
      },
      {
        "review_id": 124
      }
    ]
  end

  def business_type
    @business_type ||= business.type.to_sym == :restaurant ? 'restaurant' : business.type.to_sym == :hotel ? 'hotel' : 'business'
  end

  def inference_response
    raw_output = response.dig('choices', 0, 'message', 'content')
    cleaned_output = raw_output.gsub(/```json\n|\n```/, '')
    JSON.parse(cleaned_output)
  end

  def input_token_count
    response.dig('usage', 'prompt_tokens') || 0
  end

  def output_token_count
    response.dig('usage', 'completion_tokens') || 0
  end
end
