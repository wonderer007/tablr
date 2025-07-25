class Apify::UpdatePlaceJob < ApplicationJob
  queue_as :default

  def perform(place_id:)
    place = Place.find(place_id)

    ActsAsTenant.with_tenant(place) do
      Apify::UpdatePlace.call(place_id: place.id)
    end
  end
end
