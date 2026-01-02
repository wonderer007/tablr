# frozen_string_literal: true

class OnboardingController < ApplicationController
  layout 'auth'
  before_action :authenticate_user!
  before_action :ensure_needs_onboarding, except: [:complete]
  before_action :ensure_has_business

  # Step 1: Business Name
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

  # Step 2: Platform Selection
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

  # Step 3: Integration URL
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

    if @business.update(url: url, business_type: business_type)
      session.delete(:selected_integration)
      redirect_to onboarding_plan_path
    else
      render :integration_url, status: :unprocessable_entity
    end
  end

  # Step 4: Plan Selection
  def plan
    @business = current_user.business
    @free_plan = Business::PLAN_FEATURES[:free]
    @pro_plan = Business::PLAN_FEATURES[:pro]
  end

  def select_plan
    @business = current_user.business
    selected_plan = params[:plan]&.to_sym

    unless %i[free pro].include?(selected_plan)
      redirect_to onboarding_plan_path, alert: 'Please select a valid plan'
      return
    end

    if @business.update(plan: selected_plan, onboarding_completed: true)
      if selected_plan == :pro
        # Redirect to payment for Pro plan
        redirect_to payment_processing_path
      else
        # Free plan - start syncing reviews immediately
        Apify::SyncBusinessJob.perform_later(business_id: @business.id)
        redirect_to onboarding_complete_path
      end
    else
      render :plan, status: :unprocessable_entity
    end
  end

  # Complete
  def complete
    @business = current_user.business
  end

  private

  def ensure_needs_onboarding
    if !current_user.needs_onboarding? && params[:change_plan] != 'true'
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
