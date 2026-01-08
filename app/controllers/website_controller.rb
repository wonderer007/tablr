class WebsiteController < ApplicationController
  layout 'landing'

  def index
  end

  def unsubscribe
    if params[:token].present?
      contact = Marketing::Contact.find_by(unsubscribe_token: params[:token])
      if contact
        @email = contact.email
        contact.update(unsubscribed: true)
      else
        @email = nil
        @error = "Invalid unsubscribe link"
      end
    elsif params[:email].present?
      # Legacy email-based unsubscribe (less secure, but maintains backward compatibility)
      @email = params[:email]
      contact = Marketing::Contact.find_by(email: @email)
      contact&.update(unsubscribed: true)
    else
      @email = nil
      @error = "Invalid unsubscribe link"
    end
  end
end
