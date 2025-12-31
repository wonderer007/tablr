class AddEmailNotificationTimeToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :email_notification_time, :integer, default: 0
  end
end

