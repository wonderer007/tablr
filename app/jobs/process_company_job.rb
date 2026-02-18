class ProcessCompanyJob < ApplicationJob
  queue_as :process_company

  sidekiq_options throttle: { concurrency: { limit: 2 } }

  def perform(company_id)
    company = Marketing::Company.find(company_id)

    FindGoogleMapJob.new.perform(company.id)

    company.reload

    if company.google_map_url.blank?
      puts "Google Map URL not found"
      return
    end

    # check if we have send any email to the company contacts 
    marketing_emails = company.marketing_emails.where(status: "sent")
    if marketing_emails.any?
      puts "Emails already sent to the company contacts"
      return
    end

    # randomly select a contact
    marketing_contact = company.marketing_contacts.where(email_status: nil).sample

    if marketing_contact.blank?
      puts "No marketing contact found for the company"
      return
    end

    # verify marketing contact email
    if marketing_contact.email_status.blank?
      result = Marketing::EmailVerifier.new(marketing_contact.email).call

      if result[:error]
        puts "Email verification failed: #{result[:error]}"
        return
      end

      marketing_contact.update!(
        email_status: result[:email_status],
        never_bounce_response: result[:never_bounce_response]
      )
    end

    if marketing_contact.email_status == "valid"
      business = Business.find_or_initialize_by(url: company.google_map_url)
      business.status = :created
      business.business_type = :google_place
      business.test = true
      business.plan = 'free'

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
      puts "Business created and linked to company."
    end
  end
end
