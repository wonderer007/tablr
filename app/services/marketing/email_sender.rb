module Marketing
  module EmailSender
    class << self
      def send_for_company(company)
        draft_email = company.marketing_emails.find_by(status: "draft")

        company.marketing_contacts.where(unsubscribed: false).each do |contact|
          send_to_contact(company: company, contact: contact, draft_email: draft_email)
        end
      end

      def default_subject_for(company)
        "Unlock 22% Revenue Growth from #{company.name&.downcase&.split&.map(&:titleize)&.join(" ")} Reviews"
      end

      private

      def send_to_contact(company:, contact:, draft_email:)
        return if contact.marketing_emails.where(sent_at: 30.days.ago..).any?

        ai_generated_intro = draft_email&.ai_generated_intro
        email_content = PromotionalMailer.cold_email_outreach(contact, ai_generated_intro: ai_generated_intro).deliver_later

        if draft_email.present? && draft_email.marketing_contact.id == contact.id
          draft_email.update(sent_at: Time.current, status: "sent")
        else
          Marketing::Email.create(
            marketing_contact: contact,
            subject: default_subject_for(company),
            body: draft_email.body.to_s,
            sent_at: Time.current,
            status: "sent",
            error_message: nil
          )
        end
      end
    end
  end
end

