class AddEmailNotificationToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :email_notification, :boolean, default: true, null: false
  end
end

