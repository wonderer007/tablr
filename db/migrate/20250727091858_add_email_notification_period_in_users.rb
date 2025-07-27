class AddEmailNotificationPeriodInUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :email_notification_period, :integer, default: 2
  end
end
