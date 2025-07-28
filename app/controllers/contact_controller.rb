class ContactController < ApplicationController
  layout 'auth'

  def new
    # This will be the contact/pre-registration page
  end

  def create
    @contact_params = contact_params
    
    if @contact_params[:name].present? && @contact_params[:email].present?
      begin
        ActiveRecord::Base.transaction do
          # Create Place
          place = Place.create!(
            name: @contact_params[:restaurant_name],
            url: @contact_params[:google_maps_link]
          )

          # Split name into first and last name (naive split)
          names = @contact_params[:name].to_s.strip.split(' ', 2)
          first_name = names[0]
          last_name = names[1] || ''

          # Create User
          user = User.create!(
            email: @contact_params[:email],
            password: SecureRandom.hex(10),
            first_name: first_name,
            last_name: last_name,
            phone_number: @contact_params[:phone_number],
            place: place
          )
        end
        redirect_to new_contact_path, notice: 'Thank you for your submission! We will contact you soon to set up your account.'
      rescue ActiveRecord::RecordInvalid => e
        flash.now[:alert] = 'Something went wrong. Please try again.'
        render :new
      end
    else
      flash.now[:alert] = 'Something went wrong. Please try again.'
      render :new
    end
  end

  private

  def contact_params
    params.permit(:name, :email, :phone_number, :restaurant_name, :google_maps_link, :message)
  end
end
