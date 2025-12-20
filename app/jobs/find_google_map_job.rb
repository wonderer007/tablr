class FindGoogleMapJob < ApplicationJob
  queue_as :default

  def perform(company_id)
    company = Marketing::Company.find(company_id)
    return if company.google_map_url.present?

    google_map_url = FindGoogleMapPlace.new(company_id: company.id).call
    return if google_map_url.blank?

    company.update(google_map_url: google_map_url)
  end
end
