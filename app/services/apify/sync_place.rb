class Apify::SyncPlace < ApplicationService
  attr_accessor :place_id

  def initialize(place_id:)
    @place_id = place_id
  end

  def call
    return if can_sync?

    data = Apify::Client.start_run(Place::ACTOR_ID, {
      language: "en",
      skipClosedPlaces: false,
      startUrls: [
          {
              url: place.url,
              method: "GET"
          }
      ]
    })

    place.update(status: :syncing_place, place_actor_run_id: data.dig('data', 'id'))
  end

  def can_sync?
    place.status.in?([:created, :synced_reviews, :failed])
  end

  def place
    @place ||= Place.find(@place_id)
  end
end
