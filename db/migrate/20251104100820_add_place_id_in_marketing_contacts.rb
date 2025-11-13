class AddPlaceIdInMarketingContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_contacts, :place_id, :bigint, null: true
    add_index :marketing_contacts, :place_id
  end
end
