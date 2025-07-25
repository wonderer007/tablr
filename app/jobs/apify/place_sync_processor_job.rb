class Apify::PlaceSyncProcessorJob < ApplicationJob
  queue_as :default

  def perform
    places = Place.where(status: [:syncing_place, :synced_place, :syncing_reviews])

    places.each do |place|
      run_sync_service(place)
    end
  end

  private

  def run_sync_service(place)
    case place.status.to_sym
    when :syncing_place
      Apify::UpdatePlaceJob.perform_later(place_id: place.id)
    when :synced_place
      Apify::SyncReviewsJob.perform_later(place_id: place.id)
    when :syncing_reviews
      Apify::UpdateReviewsJob.perform_later(place_id: place.id)
    end
  end
end
