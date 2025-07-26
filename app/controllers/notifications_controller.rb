class NotificationsController < DashboardController
  before_action :set_notification

  def mark_read
    @notification.update(read: true)
    respond_to do |format|
      format.html { redirect_back fallback_location: dashboard_path, notice: 'Notification marked as read.' }
      format.js   # For Turbo/remote
      format.json { head :no_content }
    end
  end

  private

  def set_notification
    @notification = current_place.notifications.find(params[:id])
  end
end
