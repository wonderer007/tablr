class MigrateCompanyDataToCompaniesTable < ActiveRecord::Migration[7.2]
  def up
    # Create companies from unique company names in marketing_contacts
    execute <<-SQL
      INSERT INTO marketing_companies (name, linkedin_url, address, city, state, country, phone, google_map_url, place_id, created_at, updated_at)
      SELECT DISTINCT
        company,
        company_linkedin_url,
        company_address,
        company_city,
        company_state,
        company_country,
        company_phone,
        google_map_url,
        place_id,
        NOW(),
        NOW()
      FROM marketing_contacts
      WHERE company IS NOT NULL AND company != ''
    SQL

    # Update marketing_contacts to set company_id
    execute <<-SQL
      UPDATE marketing_contacts
      SET company_id = marketing_companies.id
      FROM marketing_companies
      WHERE marketing_contacts.company = marketing_companies.name
        AND marketing_contacts.place_id = marketing_companies.place_id
    SQL
  end

  def down
    # This migration is not reversible as it involves data transformation
    # The company data would need to be manually restored from backups if needed
  end
end
