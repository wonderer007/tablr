class AddModelToMarketingEmails < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_emails, :model, :string
  end
end
