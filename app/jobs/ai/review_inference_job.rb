class Ai::ReviewInferenceJob < ApplicationJob
  queue_as :default

  def perform(place_id:, review_ids:)
    place = Place.find(place_id)

    return unless place.payment_approved?


    ActsAsTenant.with_tenant(place) do
      reviews_start_date = place.reviews.where(id: review_ids).order(published_at: :asc).first&.published_at&.to_date
      reviews_end_date = place.reviews.where(id: review_ids).order(published_at: :desc).first&.published_at&.to_date

      place.reviews.where(id: review_ids, processed: false).pluck(:id).each_slice(Ai::ReviewInference::BATCH_LIMIT) do |batch|
        Ai::ReviewInference.call(place_id: place.id, review_ids: batch)
        place.reviews.where(id: batch).update_all(processed: true)
      end

      keyword_count = Keyword.where(review_id: review_ids).count
      suggestion_count = Suggestion.where(review_id: review_ids).count
      complain_count = Complain.where(review_id: review_ids).count
      review_count = Review.where(id: review_ids).count

      Notification.create!(notification_type: :review, place: place, text: "#{review_count} new reviews") if review_count > 0
      Notification.create!(notification_type: :complain, place: place, text: "#{complain_count} new complains") if complain_count > 0
      Notification.create!(notification_type: :suggestion, place: place, text: "#{suggestion_count} new suggestions") if suggestion_count > 0
      Notification.create!(notification_type: :keyword, place: place, text: "#{keyword_count} new keywords") if keyword_count > 0

      if reviews_start_date && reviews_end_date
        RestaurantReportMailer.periodic_report(place.users.first, place, reviews_start_date, reviews_end_date).deliver_later
      end

      place.update(first_inference_completed: true)
    end
  end
end
