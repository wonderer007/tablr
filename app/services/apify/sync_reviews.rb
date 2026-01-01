class Apify::SyncReviews < ApplicationService
  attr_accessor :business_id

  def initialize(business_id:)
    @business_id = business_id
  end

  def max_reviews
    business.test ? Review::REVIEW_COUNT_FOR_TEST : Review::MAX_REVIEW_COUNT
  end

  def call    
    return unless business.payment_approved?
    return if business.status.to_sym == :syncing_place || business.status.to_sym == :syncing_reviews

    params = {
      language: 'en',
      reviewsSort: 'newest',
      placeIds: [business.data['placeId']],
      maxReviews: max_reviews,
    }.merge(reviews_since)

    data = Apify::Client.start_run(Review::ACTOR_ID, params)
    return if data.blank?

    business.update(status: :syncing_reviews, review_actor_run_id: data.dig('data', 'id'))
  end

  def business
    @business ||= Business.find(@business_id)
  end

  def reviews_since
    return {} if business.reviews.empty?

    {
      reviewsStartDate: business.reviews.order(published_at: :desc).first.published_at&.utc&.iso8601
    }
  end
end
