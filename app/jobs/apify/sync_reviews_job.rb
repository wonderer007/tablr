class Apify::SyncReviewsJob < ApplicationJob
  queue_as :default

  def perform(business_id:)
    business = Business.find(business_id)

    ActsAsTenant.with_tenant(business) do
      Apify::SyncReviews.call(business_id: business.id)
    end
  end
end
