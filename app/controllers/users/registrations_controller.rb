class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout
  before_action :configure_sign_up_params, only: [:create]

  helper_method :current_place

  def create
    # Build user resource without place-specific params
    build_resource(sign_up_params.except(:google_maps_url))

    # Use transaction to ensure atomic operation
    ActiveRecord::Base.transaction do
      place = Place.create!(url: sign_up_params[:google_maps_url])

      # Associate place with user
      resource.place = place

      # Save user
      if resource.save
        yield resource if block_given?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        # If user save fails, raise error to rollback transaction
        raise ActiveRecord::Rollback
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback => e
    # Handle validation errors
    clean_up_passwords resource
    set_minimum_password_length
    
    # Add place-related errors to user if needed
    if e.is_a?(ActiveRecord::RecordInvalid) && e.record.is_a?(Place)
      resource.errors.add(:google_maps_url, e.record.errors.full_messages.join(', '))
    end
    
    respond_with resource
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, :last_name, :google_maps_url
    ])
  end

  private

  def resolve_layout
    case action_name
    when 'edit', 'update'
      'dashboard'
    else
      'auth'
    end
  end

  def current_place
    current_user.place
  end
end 