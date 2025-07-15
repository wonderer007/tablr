class Review < ApplicationRecord
  ACTOR_ID = 'Xb8osYTtOjlsgI6k9'
  REVIEWS_START_DATE = '2025-04-01'
  MAX_REVIEW_COUNT = 1000

  belongs_to :place
  has_many :keywords
  has_many :suggestions
  has_many :complains

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[stars food_rating service_rating atmosphere_rating published_at created_at processed text external_review_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[place keywords suggestions complains]
  end

  def self.tokenizer
    @tokenizer ||= Tiktoken.encoding_for_model("text-embedding-3-small")
  end

  def self.token_count(text)
    return 0 if text.blank?
    tokenizer.encode(text).length
  end
end
