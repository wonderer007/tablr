require 'openai'

class Ai::ReviewInference < ApplicationService
  attr_reader :place_id, :review_ids

  BATCH_LIMIT = 100

  def initialize(place_id, review_ids)
    @place_id = place_id
    @review_ids = review_ids
  end

  def call
    return if reviews.empty?

    inference_response.each_with_index do |inference, index|
      review = reviews[index]

      inference.fetch('analysis', {}).each do |category_name, items|
        category = Category.find_or_create_by(name: category_name)
        items.each do |item|
          Keyword.create(
            review_id: review.id,
            category: category,
            name: item['name'],
            sentiment: item['sentiment'],
            sentiment_score: item['sentiment_score'],
            is_dish: item['is_dish'] || false
          )
        end
      end

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

      review.update(processed: true, sentiment: inference.dig('sentiment'))
    end
  end

  private

  def response
    @response ||= client.chat(
      parameters: {
        model: "gpt-4o",
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: "You are an AI expert and restaurant review analysis assistant. Your task is to analyze a batch of customer reviews and return structured JSON output for each review, in the same order..."
          },
          {
            role: "user",
            content: <<~PROMPT
              ### INSTRUCTIONS:
              1. For each review, analyze categories: food, service, ambiance, pricing, timing, cleanliness and review overall sentiment (positive, negative, neutral).
              2. For each category, return: name, sentiment, sentiment_score. Add is_dish: true for dishes.
              3. Extract complains/suggestions with category.
              4. Omit categories not mentioned to save tokens.

              ### INPUT:
              #{reviews.pluck(:text)}

              ### OUTPUT FORMAT (JSON):
              #{output_sample.to_json}
            PROMPT
          }
        ]
      }
    )
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end

  def reviews
    @reviews ||= place.reviews.where(id: review_ids, processed: false)
                              .where.not(text: nil)
                              .limit(BATCH_LIMIT)
                              .select(:id, :text, :processed, :place_id)
  end

  def place
    @place ||= Place.find(place_id)
  end

  def output_sample
    [
      {
        "sentiment": "positive",
        "complains": {
          "service": ["service was slow"],
          "cleanliness": ["place was not very clean"]
        },
        "suggestions": {
          "reservation": ["booking a table in advance"]
        },
        "analysis": {
          "food": [
            {
              "name": "chicken karahi",
              "sentiment": "positive",
              "sentiment_score": 88,
              "is_dish": true
            }
          ],
          "service": [
            {
              "name": "wait time",
              "sentiment": "negative",
              "sentiment_score": 30
            }
          ],
          "cleanliness": [
            {
              "name": "general",
              "sentiment": "neutral",
              "sentiment_score": 40
            }
          ]
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
