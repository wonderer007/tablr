module Marketing
  class CompleteProcessingJob < ApplicationJob
    queue_as :default

    def perform(company_id)
      company = Marketing::Company.find(company_id)

      find_google_map_place(company)
      verify_contact_emails(company)

      company.reload

      if company.google_map_url.present? &&
         company.business.blank? &&
         company.marketing_contacts.where(email_status: :valid).exists?
        create_business(company)
      end
    end

    private

    def find_google_map_place(company)
      return if company.google_map_url.present?

      google_map_url = FindGoogleMapPlace.new(company_id: company.id).call
      company.update(google_map_url: google_map_url) if google_map_url.present?
    end

    def verify_contact_emails(company)
      company.marketing_contacts.where(email_status: nil).find_each do |contact|
        result = Marketing::EmailVerifier.new(contact.email).call
        next if result[:error]

        contact.update!(
          email_status: result[:email_status],
          never_bounce_response: result[:never_bounce_response]
        )
      end
    end

    def create_business(company)
      business = Business.find_or_initialize_by(url: company.google_map_url)
      business.status = :created
      business.business_type = :google_place
      business.test = true
      business.plan = 'free'

      return unless business.save

      company.update(business: business)
      business.update!(payment_approved: true, onboarding_completed: true, plan: 'free')

      random_password = SecureRandom.hex(10)
      business.users.create!(
        email: "testuser#{business.id}@tablr.io",
        first_name: "Test",
        last_name: "User",
        password: random_password,
        password_confirmation: random_password
      )
      Apify::SyncBusinessJob.perform_later(business_id: business.id)
    end
  end
end
