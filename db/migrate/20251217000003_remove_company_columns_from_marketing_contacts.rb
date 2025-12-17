class RemoveCompanyColumnsFromMarketingContacts < ActiveRecord::Migration[7.2]
  def change
    rename_column :marketing_contacts, :company, :company_name
    remove_column :marketing_contacts, :company_linkedin_url, :string
    remove_column :marketing_contacts, :company_address, :string
    remove_column :marketing_contacts, :company_city, :string
    remove_column :marketing_contacts, :company_state, :string
    remove_column :marketing_contacts, :company_country, :string
    remove_column :marketing_contacts, :company_phone, :string
    remove_column :marketing_contacts, :google_map_url, :string
    remove_column :marketing_contacts, :place_id, :bigint
  end
end
