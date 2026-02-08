module Webhooks
  class ResendController < ApplicationController
    skip_before_action :verify_authenticity_token

    # Supported Resend webhook event types
    SUPPORTED_EVENTS = %w[
      email.bounced
      email.clicked
      email.complained
      email.delivered
      email.delivery_delayed
      email.failed
      email.opened
      email.received
      email.scheduled
      email.sent
      email.suppressed
    ].freeze

    def emails
      unless verify_webhook_signature
        Rails.logger.warn "Resend webhook: Invalid signature"
        return render json: { error: "Invalid signature" }, status: :unauthorized
      end

      begin
        payload = JSON.parse(raw_body)
        event_type = payload["type"]

        unless SUPPORTED_EVENTS.include?(event_type)
          Rails.logger.info "Resend webhook: Ignoring unsupported event #{event_type}"
          return render json: { message: "Event ignored" }, status: :ok
        end

        process_email_event(event_type, payload)
        render json: { message: "Webhook processed" }, status: :ok

      rescue JSON::ParserError => e
        Rails.logger.error "Resend webhook: Invalid JSON payload - #{e.message}"
        render json: { error: "Invalid JSON payload" }, status: :bad_request
      rescue StandardError => e
        Rails.logger.error "Resend webhook: Error processing webhook - #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
        render json: { error: "Internal server error" }, status: :internal_server_error
      end
    end

    private

    def verify_webhook_signature
      secret = ENV["RESEND_WEBHOOK_SECRET"]
      return false if secret.blank?

      headers = {
        "svix-id" => request.headers["svix-id"],
        "svix-timestamp" => request.headers["svix-timestamp"],
        "svix-signature" => request.headers["svix-signature"]
      }

      begin
        wh = Svix::Webhook.new(secret)
        wh.verify(raw_body, headers)
        true
      rescue Svix::WebhookVerificationError => e
        Rails.logger.warn "Resend webhook: Signature verification failed - #{e.message}"
        false
      rescue StandardError => e
        Rails.logger.error "Resend webhook: Error verifying signature - #{e.message}"
        false
      end
    end

    def raw_body
      @raw_body ||= begin
        request.body.rewind
        body = request.body.read
        request.body.rewind
        body
      end
    end

    def process_email_event(event_type, payload)
      data = payload["data"]
      resend_email_id = data["email_id"]

      if resend_email_id.blank?
        Rails.logger.warn "Resend webhook: No email_id in payload"
        return
      end

      email = Marketing::Email.find_by(resend_email_id: resend_email_id)

      if email.nil?
        Rails.logger.info "Resend webhook: No Marketing::Email found for resend_email_id #{resend_email_id}"
        return
      end

      # Extract status from event type (e.g., "email.delivered" -> "delivered")
      resend_status = event_type.split(".").last

      email.update!(
        resend_status: resend_status,
        webhook_payload: payload
      )

      Rails.logger.info "Resend webhook: Updated Marketing::Email #{email.id} with status #{resend_status}"

      # Handle special cases
      case resend_status
      when "bounced", "failed", "complained", "suppressed"
        handle_delivery_failure(email, resend_status, data)
      end
    end

    def handle_delivery_failure(email, status, data)
      # Log detailed bounce/failure info for debugging
      case status
      when "bounced"
        bounce_info = data["bounce"]
        if bounce_info
          Rails.logger.warn "Resend webhook: Email #{email.id} bounced - Type: #{bounce_info['type']}, " \
                            "SubType: #{bounce_info['subType']}, Message: #{bounce_info['message']}"
        end
      when "complained"
        Rails.logger.warn "Resend webhook: Email #{email.id} marked as spam by recipient"
      when "failed"
        Rails.logger.warn "Resend webhook: Email #{email.id} failed to send"
      when "suppressed"
        Rails.logger.warn "Resend webhook: Email #{email.id} was suppressed by Resend"
      end
    end
  end
end
