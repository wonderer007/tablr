class AddUnsubscribeReasonToMarketingContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_contacts, :unsubscribe_reason, :string
  end
end

