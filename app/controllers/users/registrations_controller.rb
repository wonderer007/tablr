class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout

  helper_method :current_place

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