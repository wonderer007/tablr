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
        return if contact.marketing_emails.where(status: 'sent', sent_at: 30.days.ago..).any?

        # Determine subject and body
        if draft_email.present? && draft_email.body.present?
          subject = draft_email.subject.presence || default_subject_for(company)
          html_body = render_draft_email(contact, draft_email.body)
        else
          subject = "Unlock 22% Revenue Growth from #{format_company_name(contact.company)} Reviews"
          html_body = render_cold_email(contact)
        end

        # Build headers
        headers = {
          "List-Unsubscribe" => "<#{unsubscribe_url(contact)}>"
        }

        # Send via Resend API to capture email_id
        result = ResendEmailService.send_email(
          to: contact.email,
          subject: subject,
          html: html_body,
          headers: headers
        )

        # Update or create the email record with resend_email_id
        if draft_email.present? && draft_email.marketing_contact_id == contact.id
          draft_email.update(
            sent_at: Time.current,
            status: "sent",
            resend_email_id: result[:email_id],
            error_message: result[:success] ? nil : result[:error]
          )
        else
          Marketing::Email.create(
            marketing_contact: contact,
            subject: subject,
            body: draft_email&.body.to_s,
            sent_at: Time.current,
            status: "sent",
            model: draft_email&.model.presence || Marketing::Email::DEFAULT_MODEL,
            resend_email_id: result[:email_id],
            error_message: result[:success] ? nil : result[:error]
          )
        end
      end

      def render_draft_email(contact, body)
        recipient_name = recipient_name_for(contact)
        unsubscribe_link = "<a href=\"#{unsubscribe_url(contact)}\" target=\"_blank\">Unsubscribe</a>"

        processed_body = body.to_s
          .gsub("{{RECIPIENT_NAME}}", recipient_name)
          .gsub("{{UNSUBSCRIBE_LINK}}", unsubscribe_link)

        # Wrap in basic HTML structure
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
          </head>
          <body>
            #{processed_body}
          </body>
          </html>
        HTML
      end

      def render_cold_email(contact)
        # Use ActionMailer to render the template, then extract HTML
        mail = PromotionalMailer.cold_email_outreach(contact, ai_generated_intro: nil)
        mail.body.to_s
      end

      def recipient_name_for(contact)
        if contact.first_name.present? && contact.first_name.length > 1
          contact.first_name
        elsif contact.last_name.present? && contact.last_name.length > 1
          contact.last_name
        elsif contact.email.present?
          contact.email.split("@").first
        else
          "there"
        end
      end

      def format_company_name(company)
        company.name.downcase.split.map(&:titleize).join(" ").gsub(".", "")
      end

      def unsubscribe_url(contact)
        Rails.application.routes.url_helpers.unsubscribe_url(
          token: contact.unsubscribe_token,
          host: "tablr.org"
        )
      end
    end
  end
end
