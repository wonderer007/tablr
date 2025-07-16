class Review < ApplicationRecord
  ACTOR_ID = 'Xb8osYTtOjlsgI6k9'
  REVIEWS_START_DATE = '2025-04-01'
  MAX_REVIEW_COUNT = 1000

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

  # assignment sentiment based on the keywords
  # if positive keyword count is more than negative keyword count, then sentiment is positive
  # if negative keyword count is more than positive keyword count, then sentiment is negative
  # if positive and negative keyword count is equal, then sentiment is neutral
  # if no keywords, then sentiment is neutral
  def assign_sentiment
    return if sentiment.present?

    positive_keywords = keywords.where(sentiment: :positive).count
    negative_keywords = keywords.where(sentiment: :negative).count
    if positive_keywords > negative_keywords
      self.sentiment = :positive
    elsif negative_keywords > positive_keywords
      self.sentiment = :negative
    else
      self.sentiment = :neutral
    end

    save!
  end
end
