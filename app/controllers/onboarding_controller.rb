# frozen_string_literal: true

class OnboardingController < ApplicationController
  layout 'auth'
  before_action :authenticate_user!
  before_action :ensure_needs_onboarding, except: [:complete]
  before_action :ensure_has_business

  def business_name
    @business = current_user.business
  end

  def update_business_name
    @business = current_user.business

    if @business.update(business_name_params)
      redirect_to onboarding_integrations_path
    else
      render :business_name, status: :unprocessable_entity
    end
  end

  def integrations
    @business = current_user.business
    @available_integrations = Business::AVAILABLE_INTEGRATIONS
    @selected_integration = session[:selected_integration]
  end

  def select_integration
    integration = params[:integration]&.to_sym

    if Business::AVAILABLE_INTEGRATIONS.find { |i| i[:id] == integration }
      session[:selected_integration] = integration
      redirect_to onboarding_integration_url_path
    else
      redirect_to onboarding_integrations_path, alert: 'Please select a valid integration'
    end
  end

  def integration_url
    @integration = Business::AVAILABLE_INTEGRATIONS.find { |i| i[:id] == session[:selected_integration]&.to_sym }

    unless @integration
      redirect_to onboarding_integrations_path, alert: 'Please select an integration first'
      return
    end

    @business = current_user.business
  end

  def save_integration_url
    @integration = Business::AVAILABLE_INTEGRATIONS.find { |i| i[:id] == session[:selected_integration]&.to_sym }
    @business = current_user.business

    url = params[:business][:url]
    business_type = Business::INTEGRATION_TO_BUSINESS_TYPE[session[:selected_integration]&.to_sym] || :google_place

    if @business.update(url: url, business_type: business_type, onboarding_completed: true)
      session.delete(:selected_integration)

      # Trigger the sync job if payment is approved
      Apify::SyncBusinessJob.perform_later(business_id: @business.id) if current_user.payment_approved?

      redirect_to onboarding_complete_path
    else
      render :integration_url, status: :unprocessable_entity
    end
  end

  def complete
    @business = current_user.business
  end

  private

  def ensure_needs_onboarding
    unless current_user.needs_onboarding?
      redirect_to dashboard_path
    end
  end

  def ensure_has_business
    return if current_user.business.present?

    current_user.create_business!(business_type: :google_place, status: :created)
  end

  def business_name_params
    params.require(:business).permit(:name)
  end
end

