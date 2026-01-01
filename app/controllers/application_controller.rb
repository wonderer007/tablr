class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    if resource.is_a?(User)
      business = resource.business
      
      # Check onboarding first
      if resource.needs_onboarding?
        onboarding_path
      # Free plan users skip payment
      elsif business&.free?
        dashboard_path
      # Pro plan users need payment approval
      elsif business&.pro? && !business.payment_approved?
        payment_processing_path
      else
        dashboard_path
      end
    else
      super
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone_number, :business_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone_number])
  end
end
