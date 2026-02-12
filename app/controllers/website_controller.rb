class WebsiteController < ApplicationController
  layout 'landing'

  def index
  end

  def unsubscribe
    @token = params[:token]
    @email = params[:email]

    if @token.present?
      contact = Marketing::Contact.find_by(unsubscribe_token: @token)
      contact&.update(unsubscribed: true)
    elsif @email.present?
      contact = Marketing::Contact.find_by(email: @email)
      contact&.update(unsubscribed: true)
    end

    @unsubscribed = params[:success] == "true"
  end

  def process_unsubscribe
    token = params[:token]
    email = params[:email]
    reason = params[:reason]
    other_reason = params[:other_reason]

    # Combine reason with other_reason if "other" was selected
    full_reason = reason == "other" && other_reason.present? ? "Other: #{other_reason}" : reason

    # Try to find and update the contact, but don't show error if not found
    if token.present?
      contact = Marketing::Contact.find_by(unsubscribe_token: token)
      contact&.update(unsubscribed: true, unsubscribe_reason: full_reason)
    elsif email.present?
      contact = Marketing::Contact.find_by(email: email)
      contact&.update(unsubscribed: true, unsubscribe_reason: full_reason)
    end

    # Redirect with success parameter
    redirect_to unsubscribe_path(success: true)
  end
end
