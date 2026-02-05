class AddNeverBounceFieldsToMarketingContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_contacts, :never_bounce_response, :jsonb
    add_column :marketing_contacts, :email_status, :string
    add_index :marketing_contacts, :email_status
  end
end
