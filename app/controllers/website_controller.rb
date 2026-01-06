class WebsiteController < ApplicationController
  layout 'landing'

  def index
  end

  def unsubscribe
    # Support both token-based (new) and email-based (legacy) unsubscribe
    if params[:token].present?
      @email = Rails.application.message_verifier(:unsubscribe).verify(params[:token], purpose: :unsubscribe)
    else
      @email = params[:email]
    end

    if @email.present?
      contact = Marketing::Contact.find_by(email: @email)
      contact&.update(unsubscribed: true)
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    @email = nil
    @error = "Invalid or expired unsubscribe link"
  end
end
