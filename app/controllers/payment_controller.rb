class PaymentController < ApplicationController
  before_action :authenticate_user!, except: [:lemonsqueezy_webhook]
  skip_before_action :verify_authenticity_token, only: [:lemonsqueezy_webhook]
  layout 'auth'

  def processing
    if current_user.payment_approved?
      redirect_to dashboard_path and return
    end

    @payment_url = "#{ENV['PAYMENT_URL']}?checkout[custom][email]=#{current_user.email}&checkout[custom][tenant]=#{current_user.place.id}"
  end

  def lemonsqueezy_webhook
    # Get the raw request body for signature verification
    request.body.rewind
    raw_body = request.body.read
    request.body.rewind
    
    signature = request.headers['X-Signature']
    webhook_secret = ENV['LEMON_SQUEEZY_SIGNATURE']
    # Verify the HMAC signature
    unless verify_webhook_signature(raw_body, signature, webhook_secret)
      Rails.logger.warn "Lemon Squeezy webhook: Invalid signature"
      return render json: { error: 'Invalid signature' }, status: :unauthorized
    end

    begin
      payload = JSON.parse(raw_body)

      event_name = payload.dig('meta', 'event_name')
      unless event_name == 'subscription_created'
        Rails.logger.info "Lemon Squeezy webhook: Ignoring event #{event_name}"
        return render json: { message: 'Event ignored' }, status: :ok
      end

      tenant_id = payload.dig('meta', 'custom_data', 'tenant')
      customer_email = payload.dig('meta', 'custom_data', 'email')

      if customer_email.blank? || tenant_id.blank?
        Rails.logger.error "Lemon Squeezy webhook: No customer email or tenant id found in payload"
        return render json: { error: 'Customer email or tenant id not found' }, status: :bad_request
      end

      ActsAsTenant.current_tenant = Place.find(tenant_id)
      user = User.find_by(email: customer_email)

      unless user
        Rails.logger.error "Lemon Squeezy webhook: User not found for email #{customer_email}"
        return render json: { error: 'User not found' }, status: :not_found
      end

      user.update!(payment_approved: true)
      
      Rails.logger.info "Lemon Squeezy webhook: Payment approved for user #{user.email}"
      render json: { message: 'Payment status updated successfully' }, status: :ok

    rescue JSON::ParserError => e
      Rails.logger.error "Lemon Squeezy webhook: Invalid JSON payload - #{e.message}"
      render json: { error: 'Invalid JSON payload' }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "Lemon Squeezy webhook: Error processing webhook - #{e.message}"
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  private

  def verify_webhook_signature(raw_body, signature, secret)
    return false if signature.blank? || secret.blank?

    # Calculate expected signature using HMAC-SHA256
    expected_signature = OpenSSL::HMAC.hexdigest('sha256', secret, raw_body)
    
    # Use secure comparison to prevent timing attacks
    ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
  rescue StandardError => e
    Rails.logger.error "Lemon Squeezy webhook: Error verifying signature - #{e.message}"
    false
  end
end
