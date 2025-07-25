class Ai::ReviewInferenceJob < ApplicationJob
  queue_as :default

  def perform(place_id:, review_ids:)
    place = Place.find(place_id)

    ActsAsTenant.with_tenant(place) do
      review_ids.each_slice(Ai::ReviewInference::BATCH_LIMIT) do |batch|
        Ai::ReviewInference.call(place_id: place.id, review_ids: batch)
      end
    end
  end
end
