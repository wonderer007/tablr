class SettingsController < DashboardController
  def edit
  end

  def update_email_notification_period
    current_user.update(email_notification_period: params[:email_notification_period])
    redirect_to settings_path, notice: 'Email notification period updated'
  end
end
