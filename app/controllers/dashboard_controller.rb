class DashboardController < ApplicationController
  layout 'dashboard'

  before_action :authenticate_user!
  before_action :check_onboarding_completed
  before_action :check_payment_approved
  before_action :check_data_processing_complete
  set_current_tenant_through_filter
  before_action :set_current_tenant_by_user
  helper_method :current_business

  def set_current_tenant_by_user
    set_current_tenant(current_business)
  end

  def current_business
    current_user.business
  end

  def check_onboarding_completed
    if current_user.needs_onboarding?
      redirect_to onboarding_path
    end
  end

  def check_payment_approved
    unless current_user.payment_approved?
      redirect_to payment_processing_path
    end
  end

  def check_data_processing_complete
    unless current_business&.first_inference_completed?
      redirect_to data_processing_path
    end
  end
end
