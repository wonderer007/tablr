class Ai::ReviewInferenceJob < ApplicationJob
  queue_as :default

  def perform(place_id:, review_ids:)
    place = Place.find(place_id)

    ActsAsTenant.with_tenant(place) do
      review_ids.each_slice(Ai::ReviewInference::BATCH_LIMIT) do |batch|
        Ai::ReviewInference.call(place_id: place.id, review_ids: batch)
      end

      place.reviews.where(id: review_ids).update_all(processed: true)

      keyword_count = Keyword.where(review_id: review_ids).count
      suggestion_count = Suggestion.where(review_id: review_ids).count
      complain_count = Complain.where(review_id: review_ids).count
      review_count = Review.where(id: review_ids).count

      Notification.create!(notification_type: :review, place: place, text: "#{review_count} new reviews") if review_count > 0
      Notification.create!(notification_type: :complain, place: place, text: "#{complain_count} new complains") if complain_count > 0
      Notification.create!(notification_type: :suggestion, place: place, text: "#{suggestion_count} new suggestions") if suggestion_count > 0
      Notification.create!(notification_type: :keyword, place: place, text: "#{keyword_count} new keywords") if keyword_count > 0
    end
  end
end
