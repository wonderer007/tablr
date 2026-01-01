class Business < ApplicationRecord
  ACTOR_ID = '2Mdma1N6Fd0y3QEjR'

  validates :url, presence: true, uniqueness: { scope: :test }

  has_many :reviews
  has_many :users
  has_many :notifications
  has_many :inference_responses

  enum :status, [:created, :syncing_place, :synced_place, :syncing_reviews, :synced_reviews, :failed]
  enum :business_type, {
    google_place: 'google_place',
    amazon_store: 'amazon_store',
    shopify_store: 'shopify_store',
    android_app: 'android_app',
    ios_app: 'ios_app'
  }, default: 'google_place'

  def self.ransackable_attributes(auth_object = nil)
    %w[name place_actor_run_id review_actor_run_id status url rating id first_inference_completed test business_type]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def payment_approved?
    users&.first&.payment_approved?
  end

  def food_rating
    reviews = reviews.where.not(food_rating: nil)
    return 0 if reviews.empty?
    reviews.average(:food_rating).round(1)
  end

  def service_rating
    reviews = reviews.where.not(service_rating: nil)
    return 0 if reviews.empty?
    reviews.average(:service_rating).round(1)
  end

  def atmosphere_rating
    reviews = reviews.where.not(atmosphere_rating: nil)
    return 0 if reviews.empty?
    reviews.average(:atmosphere_rating).round(1)
  end

  def address
    data&.dig('address')
  end
end

