class DashboardController < ApplicationController
  layout 'dashboard'

  before_action :authenticate_user!
  before_action :check_onboarding_completed
  before_action :check_payment_approved
  before_action :check_data_processing_complete
  before_action :set_payment_url
  set_current_tenant_through_filter
  before_action :set_current_tenant_by_user
  helper_method :current_business

  def set_current_tenant_by_user
    set_current_tenant(current_business)
  end

  def current_business
    current_user.business
  end

  def set_payment_url
    @payment_url = "#{ENV['PAYMENT_URL']}?checkout[custom][email]=#{current_user.email}&checkout[custom][tenant]=#{current_business.id}"
  end

  def check_onboarding_completed
    if current_user.needs_onboarding?
      redirect_to onboarding_path
    end
  end

  def check_payment_approved
    # Skip payment check for free plan
    return if current_business&.free?
    
    # For Pro plan, check if payment is approved
    unless current_business&.payment_approved?
      redirect_to payment_processing_path
    end
  end

  def check_data_processing_complete
    unless current_business&.first_inference_completed?
      redirect_to data_processing_path
    end
  end
end
