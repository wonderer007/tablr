class Apify::UpdateBusiness < ApplicationService
  attr_reader :business_id

  def initialize(business_id:)
    @business_id = business_id
  end

  def call
    return unless business.syncing_place?

    data = Apify::Client.get_run_info(Business::ACTOR_ID, business.place_actor_run_id)

    if data.dig('data', 'status') == 'SUCCEEDED'
      results = Apify::Client.fetch_results(data.dig('data', 'defaultDatasetId'))
      if results.size == 1
        result = results.first
        business.update(
          name: result['title'],
          data: result,
          status: :synced_place,
          rating: result['totalScore'],
          place_synced_at: Time.zone.now
        )
      end
    elsif data.dig('data', 'status').in?(%w[FAILED ABORTED])
      business.update(status: :failed)
    end
  end

  def business
    @business ||= Business.find(@business_id)
  end
end

