class AddUnsubscribeTokenToMarketingContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_contacts, :unsubscribe_token, :string
    add_index :marketing_contacts, :unsubscribe_token, unique: true

    # Backfill existing contacts with tokens
    reversible do |dir|
      dir.up do
        Marketing::Contact.find_each do |contact|
          contact.update_column(:unsubscribe_token, SecureRandom.urlsafe_base64(32))
        end
      end
    end
  end
end

