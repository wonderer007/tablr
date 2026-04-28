module Marketing
  class CompleteProcessingAndEmailJob < ApplicationJob
    include Marketing::CompanyProcessing

    queue_as :default

    POLL_INTERVAL = 5.minutes
    MAX_ATTEMPTS = 6 # 30 minutes total wait for AI inference

    def perform(company_id, attempt = 0)
      company = Marketing::Company.find(company_id)

      process_company(company) if attempt.zero?

      company.reload

      return unless ready_for_ai_email?(company)

      if company.business.first_inference_completed?
        generate_and_send_ai_email(company)
      elsif attempt < MAX_ATTEMPTS
        self.class.set(wait: POLL_INTERVAL).perform_later(company_id, attempt + 1)
      else
        Rails.logger.warn(
          "[Marketing::CompleteProcessingAndEmailJob] Giving up on company=#{company_id} " \
          "after #{MAX_ATTEMPTS} attempts: AI inference not completed"
        )
      end
    end

    private

    def ready_for_ai_email?(company)
      return false if company.business.blank?
      return false if valid_contacts(company).none?
      return false if recently_sent_email?(company)

      true
    end

    def valid_contacts(company)
      company.marketing_contacts.where(unsubscribed: false, email_status: 'valid')
    end

    def recently_sent_email?(company)
      company.marketing_emails.where(status: 'sent', sent_at: 30.days.ago..).exists?
    end

    def generate_and_send_ai_email(company)
      contact = valid_contacts(company).first || company.marketing_contacts.first
      return if contact.blank?

      selected_model = Marketing::Email::MODELS.keys.sample
      result = Marketing::AiEmailGenerator.new(company: company, model: selected_model).call

      if result[:error].present?
        Rails.logger.warn(
          "[Marketing::CompleteProcessingAndEmailJob] AI email generation failed " \
          "for company=#{company.id} model=#{selected_model}: #{result[:error]}"
        )
        return
      end

      draft_email = company.marketing_emails.where(status: 'draft').first_or_initialize
      draft_email.assign_attributes(
        subject: result[:subject],
        body: result[:body],
        marketing_contact: contact,
        model: selected_model,
        status: 'draft'
      )

      unless draft_email.save
        Rails.logger.warn(
          "[Marketing::CompleteProcessingAndEmailJob] Failed to save draft for " \
          "company=#{company.id}: #{draft_email.errors.full_messages.join(', ')}"
        )
        return
      end

      Marketing::EmailSender.send_for_company(company)
    end
  end
end
