class Ai::ReviewInferenceJob < ApplicationJob
  queue_as :default

  def perform(place_id:, review_ids:, batch_id: nil)
    place = Place.find(place_id)

    Ai::ReviewInference.call(place_id: place_id, review_ids: review_ids)

    place.reviews.where(id: review_ids).update_all(processed: true)
    place.update(first_inference_completed: true)

    Ai::InferenceBatchTracker.mark_job_done(batch_id) if batch_id.present?
  end
end
