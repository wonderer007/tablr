class Ai::ReviewInferenceJob < ApplicationJob
  queue_as :default

  def perform(business_id:, review_ids:, batch_id: nil)
    business = Business.find(business_id)

    Ai::ReviewInference.call(business_id: business_id, review_ids: review_ids)

    business.reviews.where(id: review_ids).update_all(processed: true)
    business.update(first_inference_completed: true)

    Ai::InferenceBatchTracker.mark_job_done(batch_id) if batch_id.present?
  end
end
