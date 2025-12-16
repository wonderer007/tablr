class AddUnsubscribeToMarketingContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_contacts, :unsubscribed, :boolean, default: false
  end
end
