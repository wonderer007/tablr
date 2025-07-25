class Apify::SyncPlaceJob < ApplicationJob
  queue_as :default

  def perform(place_id:)
    place = Place.find(place_id)

    ActsAsTenant.with_tenant(place) do
      Apify::SyncPlace.call(place_id: place.id)
    end
  end
end
