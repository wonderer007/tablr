class CreateOutreachEmails < ActiveRecord::Migration[7.2]
  def change
    create_table :outreach_emails do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false
      t.string :company

      t.timestamps
    end

    add_index :outreach_emails, :email, unique: true
  end
end
