class Apify::UpdatePlace < ApplicationService
  attr_reader :place_id

  def initialize(place_id:)
    @place_id = place_id
  end

  def call
    return unless place.syncing_place?

    data = Apify::Client.get_run_info(Place::ACTOR_ID, place.place_actor_run_id)

    if data.dig('data', 'status') == 'SUCCEEDED'
      results = Apify::Client.fetch_results(data.dig('data', 'defaultDatasetId'))
      if results.size == 1
        result = results.first
        place.update(
          name: result['title'],
          data: result,
          status: :synced_place,
          rating: result['totalScore'],
          place_synced_at: Time.zone.now
        )
      end
    elsif data.dig('data', 'status').in?(%w[FAILED ABORTED])
      place.update(status: :failed)
    end    
  end

  def place
    @place ||= Place.find(@place_id)
  end
end