class CreateMarketingEmails < ActiveRecord::Migration[7.2]
  def change
    create_table :marketing_emails do |t|
      t.integer :marketing_contact_id
      t.integer :place_id

      t.string :subject
      t.text :body
      t.datetime :sent_at
      t.string :status
      t.text :error_message

      t.timestamps
    end
  end
end
