class Review < ApplicationRecord
  acts_as_tenant :place

  ACTOR_ID = 'Xb8osYTtOjlsgI6k9'
  MAX_REVIEW_COUNT = ENV.fetch('REVIEW_COUNT', 200)

  belongs_to :place
  has_many :keywords
  has_many :suggestions
  has_many :complains

  enum :sentiment, [:positive, :negative, :neutral]

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[stars sentiment food_rating service_rating atmosphere_rating published_at processed text]
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
