class Apify::BusinessSyncProcessorJob < ApplicationJob
  queue_as :default

  def perform
    businesses = Business.where(status: [:syncing_place, :synced_place, :syncing_reviews])

    businesses.each do |business|
      run_sync_service(business) if business.plan.to_sym == :free || (business.plan.to_sym == :pro && business.payment_approved?)
    end
  end

  private

  def run_sync_service(business)
    case business.status.to_sym
    when :syncing_place
      Apify::UpdateBusinessJob.perform_later(business_id: business.id)
    when :synced_place
      Apify::SyncReviewsJob.perform_later(business_id: business.id)
    when :syncing_reviews
      Apify::UpdateReviewsJob.perform_later(business_id: business.id)
    end
  end
end

