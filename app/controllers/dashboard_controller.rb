class DashboardController < ApplicationController
  layout 'dashboard'

  set_current_tenant_through_filter
  before_action :set_current_tenant_by_user

  def set_current_tenant_by_user
    set_current_tenant(current_place)
  end

  def current_place
    current_user.place
  end
end
