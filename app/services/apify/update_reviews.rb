class Apify::UpdateReviews < ApplicationService
  attr_reader :business_id

  def initialize(business_id:)
    @business_id = business_id
  end

  def call
    return unless business.syncing_reviews?

    data = Apify::Client.get_run_info(Review::ACTOR_ID, business.review_actor_run_id)

    if data.dig('data', 'status') == 'SUCCEEDED'
      reviews = Apify::Client.fetch_results(data.dig('data', 'defaultDatasetId'))
      unique_reviews = reviews.uniq { |review| review['reviewId'] }
      payload = unique_reviews.map do |review|
        {
          business_id: business.id,
          review_context: review['reviewContext'],
          review_url: review['reviewUrl'],
          external_review_id: review['reviewId'],
          text: review['text'],
          stars: review['stars'],
          name: review['name'],
          image_url: review['reviewerPhotoUrl'],
          likes_count: review['likesCount'],
          food_rating: review['reviewDetailedRating']['Food'],
          service_rating: review['reviewDetailedRating']['Service'],
          atmosphere_rating: review['reviewDetailedRating']['Atmosphere'],
          data: review,
          published_at: review['publishedAtDate'].to_datetime,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      end

      Review.upsert_all(payload, unique_by: [:business_id, :external_review_id])
      business.update(status: :synced_reviews, review_synced_at: Time.zone.now)

      Ai::InferenceJob.perform_later(business_id: business.id, review_ids: business.reviews.where(processed: false).pluck(:id))
    elsif data.dig('data', 'status').in?(%w[FAILED ABORTED])
      business.update(status: :failed)
    end
  end

  def business
    @business ||= Business.find(@business_id)
  end
end
