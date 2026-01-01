class SettingsController < DashboardController
  def edit
  end

  def update_email_notification_period
    current_user.assign_attributes(
      email_notification: params[:email_notification] == "true",
      email_notification_period: params[:email_notification_period],
      email_notification_time: params[:email_notification_time]
    )
    current_user.save(validate: false)
    redirect_to settings_path, notice: 'Email notification settings updated'
  end
end
