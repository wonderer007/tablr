module Marketing
  class ResendEmailService
    class << self
      # Send an email via Resend API and return the email_id
      # Returns { success: true, email_id: "..." } or { success: false, error: "..." }
      def send_email(to:, from: default_from, subject:, html:, headers: {})
        return mock_response if skip_sending?

        Resend.api_key = api_key

        params = {
          from: from,
          to: Array(to),
          subject: subject,
          html: html,
          headers: headers
        }

        response = Resend::Emails.send(params)

        if response && response[:id]
          Rails.logger.info "ResendEmailService: Email sent successfully, id: #{response[:id]}"
          { success: true, email_id: response[:id] }
        else
          Rails.logger.error "ResendEmailService: Failed to send email - #{response.inspect}"
          { success: false, error: "Failed to send email" }
        end
      rescue StandardError => e
        Rails.logger.error "ResendEmailService: Error sending email - #{e.message}"
        { success: false, error: e.message }
      end

      private

      def api_key
        ENV["OUTREACH_RESEND_API_KEY"]
      end

      def default_from
        "Haider Ali <mail@tablr.org>"
      end

      def skip_sending?
        !Rails.env.production? && ENV["FORCE_RESEND_SEND"] != "true"
      end

      def mock_response
        mock_id = "mock_#{SecureRandom.uuid}"
        Rails.logger.info "ResendEmailService: Mock mode - would have sent email, mock id: #{mock_id}"
        { success: true, email_id: mock_id }
      end
    end
  end
end
