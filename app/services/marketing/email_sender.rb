module Marketing
  module EmailSender
    class << self
      def send_for_company(company)
        draft_email = company.marketing_emails.find_by(status: "draft")

        company.marketing_contacts.where(unsubscribed: false, email_status: "valid").each do |contact|
          send_to_contact(company: company, contact: contact, draft_email: draft_email)
        end
      end

      def default_subject_for(company)
        company_name = company.name&.split&.map(&:titleize)&.join(" ")
        "Some customer feedback about #{company_name}"
      end

      private

      def send_to_contact(company:, contact:, draft_email:)
        return if contact.marketing_emails.where(sent_at: 30.days.ago..).any?

        # Use AI-generated draft if available, otherwise fall back to old template
        if draft_email.present? && draft_email.body.present?
          subject = draft_email.subject.presence || default_subject_for(company)
          PromotionalMailer.send_draft_email(contact, subject: subject, body: draft_email.body).deliver_later
        else
          PromotionalMailer.cold_email_outreach(contact, ai_generated_intro: nil).deliver_later
        end

        # Update or create the email record
        if draft_email.present? && draft_email.marketing_contact_id == contact.id
          draft_email.update(sent_at: Time.current, status: "sent")
        else
          Marketing::Email.create(
            marketing_contact: contact,
            subject: draft_email&.subject.presence || default_subject_for(company),
            body: draft_email&.body.to_s,
            sent_at: Time.current,
            status: "sent",
            error_message: nil
          )
        end
      end
    end
  end
end
