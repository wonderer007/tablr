class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout
  before_action :configure_sign_up_params, only: [:create]

  helper_method :current_business

  # Override create to handle business creation like OAuth flow
  def create
    build_resource(sign_up_params)

    ActiveRecord::Base.transaction do
      # Create business first, then associate (same as OAuth flow)
      business = Business.create!(business_type: :google_place, status: :created)
      resource.business = business
      resource.save!
    end

    yield resource if block_given?

    if resource.persisted?
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
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  rescue ActiveRecord::RecordInvalid
    clean_up_passwords resource
    set_minimum_password_length
    respond_with resource
  end

  def edit
    @business = current_user.business
    @payment_url = "#{ENV['PAYMENT_URL']}?checkout[custom][email]=#{current_user.email}&checkout[custom][tenant]=#{@business.id}"
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, :last_name
    ])
  end

  def after_sign_up_path_for(resource)
    # Redirect to onboarding flow (same as OAuth)
    onboarding_path
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

  def current_business
    current_user.business
  end
end 