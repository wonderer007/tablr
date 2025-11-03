require "securerandom"

class Ai::InferenceJob < ApplicationJob
  queue_as :default

  def perform(place_id:, review_ids:)
    place = Place.find(place_id)

    return unless place.payment_approved?

    ActsAsTenant.with_tenant(place) do
      review_scope = place.reviews.where(id: review_ids, processed: false)

      reviews_start_date = place.reviews.where(id: review_ids).order(published_at: :asc).first&.published_at&.to_date
      reviews_end_date = place.reviews.where(id: review_ids).order(published_at: :desc).first&.published_at&.to_date

      review_count = review_scope.count
      jobs_count = (review_count.to_f / Ai::ReviewInference::BATCH_LIMIT).ceil

      metadata = {
        place_id: place.id,
        review_ids: review_ids,
        reviews_start_date: reviews_start_date&.to_s,
        reviews_end_date: reviews_end_date&.to_s
      }

      batch_id = SecureRandom.uuid

      Ai::InferenceBatchTracker.register_batch(
        batch_id: batch_id,
        total_jobs: jobs_count,
        metadata: metadata
      )

      review_scope.pluck(:id).each_slice(Ai::ReviewInference::BATCH_LIMIT) do |batch|
        Ai::ReviewInferenceJob.perform_later(place_id: place.id, review_ids: batch, batch_id: batch_id)
      end
    end
  end
end
