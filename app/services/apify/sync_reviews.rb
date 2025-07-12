class Apify::SyncReviews < ApplicationService
  attr_accessor :place_id

  def initialize(place_id)
    @place_id = place_id
  end

  def call    
    return if place.status.to_sym == :syncing_place || place.status.to_sym == :syncing_reviews


    params = {
      language: 'en',
      reviewsSort: 'newest',
      placeIds: [place.data['placeId']],
      maxReviews: Review::MAX_REVIEW_COUNT,
    }

    data = Apify::Client.start_run(Review::ACTOR_ID, params)
    place.update(status: :syncing_reviews, review_actor_run_id: data.dig('data', 'id'))
  end 

  def place
    @place ||= Place.find(@place_id)
  end
end
