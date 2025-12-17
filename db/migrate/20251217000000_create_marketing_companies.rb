class CreateMarketingCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :marketing_companies do |t|
      t.string :name, null: false
      t.string :linkedin_url
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.string :phone
      t.string :google_map_url
      t.bigint :place_id

      t.timestamps
    end

    add_index :marketing_companies, :place_id
    add_foreign_key :marketing_companies, :places
  end
end
