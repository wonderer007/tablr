class PaymentController < ApplicationController
  before_action :authenticate_user!, except: [:lemonsqueezy_webhook]
  skip_before_action :verify_authenticity_token, only: [:lemonsqueezy_webhook]
  layout 'auth'

  def processing
    @business = current_user.business

    # Check if user needs onboarding first
    if current_user.needs_onboarding?
      redirect_to onboarding_path and return
    end

    # Free plan users don't need payment
    if @business&.free?
      redirect_to dashboard_path and return
    end

    # Already paid Pro users go to dashboard
    if @business&.payment_approved?
      redirect_to dashboard_path and return
    end

    @payment_url = "#{ENV['PAYMENT_URL']}?checkout[custom][email]=#{current_user.email}&checkout[custom][tenant]=#{@business.id}"
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

      business = Business.find(tenant_id)
      ActsAsTenant.current_tenant = business

      unless business
        Rails.logger.error "Lemon Squeezy webhook: Business not found for tenant_id #{tenant_id}"
        return render json: { error: 'Business not found' }, status: :not_found
      end

      # Update payment_approved on business
      business.update!(payment_approved: true)
      
      # Trigger the sync job for Pro plan after payment
      Apify::SyncBusinessJob.perform_later(business_id: business.id)
      Rails.logger.info "Lemon Squeezy webhook: Payment approved and sync triggered for business #{business.id} (email: #{customer_email})"

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
