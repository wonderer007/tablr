class AddGoogleMapUrl < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_contacts, :google_map_url, :string
  end
end
