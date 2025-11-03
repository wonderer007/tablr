class Ai::InferenceFinalizeJob < ApplicationJob
  queue_as :default

  def perform(place_id:, review_ids:, reviews_start_date: nil, reviews_end_date: nil)
    place = Place.find(place_id)

    ActsAsTenant.with_tenant(place) do
      review_ids = Array.wrap(review_ids)

      keyword_count = Keyword.where(review_id: review_ids).count
      suggestion_count = Suggestion.where(review_id: review_ids).count
      complain_count = Complain.where(review_id: review_ids).count
      review_count = Review.where(id: review_ids).count

      Notification.create!(notification_type: :review, place: place, text: "#{review_count} new reviews") if review_count.positive?
      Notification.create!(notification_type: :complain, place: place, text: "#{complain_count} new complains") if complain_count.positive?
      Notification.create!(notification_type: :suggestion, place: place, text: "#{suggestion_count} new suggestions") if suggestion_count.positive?
      Notification.create!(notification_type: :keyword, place: place, text: "#{keyword_count} new keywords") if keyword_count.positive?

      start_date = reviews_start_date.present? ? Date.parse(reviews_start_date) : nil
      end_date = reviews_end_date.present? ? Date.parse(reviews_end_date) : nil

      if place.test
      end

      if !place.test && start_date && end_date
        RestaurantReportMailer.periodic_report(place.users.first, place, start_date, end_date).deliver_later
      end
    end
  end
end

