class AddLastEmailSentAt < ActiveRecord::Migration[7.2]
  def change
    add_column :outreach_emails, :email_sent_at, :datetime
  end
end
