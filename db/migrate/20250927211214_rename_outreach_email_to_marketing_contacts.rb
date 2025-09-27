class RenameOutreachEmailToMarketingContacts < ActiveRecord::Migration[7.2]
  def up
    rename_table :outreach_emails, :marketing_contacts
  end
  
  def down
    rename_table :marketing_contacts, :outreach_emails
  end
end
