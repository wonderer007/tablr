class AddFieldsToOutreactContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :outreach_emails, :email_confidence, :float
    add_column :outreach_emails, :secondary_email, :string
    add_column :outreach_emails, :primary_email_last_verified_at, :datetime
    add_column :outreach_emails, :no_of_employees, :integer
    add_column :outreach_emails, :industry, :string
    add_column :outreach_emails, :linkedin_url, :string
    add_column :outreach_emails, :company_linkedin_url, :string
    add_column :outreach_emails, :website, :string
    add_column :outreach_emails, :twitter_url, :string
    add_column :outreach_emails, :city, :string
    add_column :outreach_emails, :country, :string
    add_column :outreach_emails, :company_address, :string
    add_column :outreach_emails, :company_city, :string
    add_column :outreach_emails, :company_state, :string
    add_column :outreach_emails, :company_country, :string
    add_column :outreach_emails, :company_phone, :string
    add_column :outreach_emails, :annual_revenue, :float

    add_index :outreach_emails, :secondary_email
  end
end
