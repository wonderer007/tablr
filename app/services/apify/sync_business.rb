class Apify::SyncBusiness < ApplicationService
  attr_accessor :business_id

  def initialize(business_id:)
    @business_id = business_id
  end

  def call
    return if can_sync?
    return unless business.payment_approved?

    data = Apify::Client.start_run(Business::ACTOR_ID, {
      language: "en",
      skipClosedPlaces: false,
      startUrls: [
          {
              url: business.url,
              method: "GET"
          }
      ]
    })

    business.update(status: :syncing_place, place_actor_run_id: data.dig('data', 'id'))
  end

  def can_sync?
    business.status.in?([:created, :synced_reviews, :failed])
  end

  def business
    @business ||= Business.find(@business_id)
  end
end

