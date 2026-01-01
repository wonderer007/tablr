class Apify::SyncBusinessJob < ApplicationJob
  queue_as :default

  def perform(business_id:)
    business = Business.find(business_id)

    return unless business.payment_approved?

    ActsAsTenant.with_tenant(business) do
      Apify::SyncBusiness.call(business_id: business.id)
    end
  end
end

