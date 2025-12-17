class AddCompanyIdToMarketingContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_contacts, :company_id, :bigint
    add_index :marketing_contacts, :company_id
    add_foreign_key :marketing_contacts, :marketing_companies, column: :company_id
  end
end
