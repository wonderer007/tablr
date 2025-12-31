class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout
  before_action :configure_sign_up_params, only: [:create]

  helper_method :current_place

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, :last_name
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