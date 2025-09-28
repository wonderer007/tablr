class Place < ApplicationRecord
  ACTOR_ID = '2Mdma1N6Fd0y3QEjR'

  validates :url, presence: true, uniqueness: { scope: :test }

  has_many :reviews
  has_many :users
  has_many :notifications

  enum :status, [:created, :syncing_place, :synced_place, :syncing_reviews, :synced_reviews, :failed]

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
end
