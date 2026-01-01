class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    # Check if payment is approved, if not redirect to payment processing
    if resource.is_a?(User) && !resource.payment_approved?
      payment_processing_path
    else
      dashboard_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone_number, :business_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone_number])
  end
end
