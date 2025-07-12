class Apify::UpdateReview < ApplicationService
  attr_reader :place_id

  def initialize(place_id)
    @place_id = place_id
  end

  def call
    return unless place.syncing_reviews?
    
    data = Apify::Client.get_run_info(Review::ACTOR_ID, place.review_actor_run_id)

    if data.dig('data', 'status') == 'SUCCEEDED'
      reviews = Apify::Client.fetch_results(data.dig('data', 'defaultDatasetId'))
      unique_reviews = reviews.uniq { |review| review['reviewId'] }
      payload = unique_reviews.map do |review|
        {
          place_id: place.id,
          review_context: review['reviewContext'],
          review_url: review['reviewUrl'],
          external_review_id: review['reviewId'],
          text: review['text'],
          likes_count: review['likesCount'],
          food_rating: review['reviewDetailedRating']['foodRating'],
          service_rating: review['reviewDetailedRating']['Service'],
          atmosphere_rating: review['reviewDetailedRating']['Atmosphere'],
          data: review,
          published_at: review['publishedAtDate'].to_datetime,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      end

      Review.upsert_all(payload, unique_by: :external_review_id)
      place.update(status: :synced_reviews, review_synced_at: Time.zone.now)
    elsif data.dig('data', 'status').in?(%w[FAILED ABORTED])
      place.update(status: :failed)
    end
  end

  def place
    @place ||= Place.find(@place_id)
  end
end