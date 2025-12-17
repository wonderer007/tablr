class Apify::SyncReviews < ApplicationService
  attr_accessor :place_id

  def initialize(place_id:)
    @place_id = place_id
  end

  def max_reviews
    place.test ? Review::REVIEW_COUNT_FOR_TEST : Review::MAX_REVIEW_COUNT
  end

  def call    
    return unless place.payment_approved?
    return if place.status.to_sym == :syncing_place || place.status.to_sym == :syncing_reviews

    params = {
      language: 'en',
      reviewsSort: 'newest',
      placeIds: [place.data['placeId']],
      maxReviews: max_reviews,
    }.merge(reviews_since)

    data = Apify::Client.start_run(Review::ACTOR_ID, params)
    return if data.blank?

    place.update(status: :syncing_reviews, review_actor_run_id: data.dig('data', 'id'))
  end

  def place
    @place ||= Place.find(@place_id)
  end

  def reviews_since
    return {} if place.reviews.empty?

    {
      reviewsStartDate: place.reviews.order(published_at: :desc).first.published_at&.utc&.iso8601
    }
  end
end
