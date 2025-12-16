class WebsiteController < ApplicationController
  layout 'landing'

  def index
  end

  def unsubscribe
    @email = params[:email]

    if @email.present?
      contact = Marketing::Contact.find_by(email: @email)
      contact&.update(unsubscribed: true)
    end
  end
end
