require "securerandom"

class Ai::InferenceJob < ApplicationJob
  queue_as :default

  def perform(business_id:, review_ids:)
    business = Business.find(business_id)

    return unless business.payment_approved?

    ActsAsTenant.with_tenant(business) do
      review_scope = business.reviews.where(id: review_ids, processed: false)

      reviews_start_date = business.reviews.where(id: review_ids).order(published_at: :asc).first&.published_at&.to_date
      reviews_end_date = business.reviews.where(id: review_ids).order(published_at: :desc).first&.published_at&.to_date

      review_count = review_scope.count
      jobs_count = (review_count.to_f / Ai::ReviewInference::BATCH_LIMIT).ceil

      metadata = {
        business_id: business.id,
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
        Ai::ReviewInferenceJob.perform_later(business_id: business.id, review_ids: batch, batch_id: batch_id)
      end
    end
  end
end
