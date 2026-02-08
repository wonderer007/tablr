class AddResendWebhookFieldsToMarketingEmails < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_emails, :resend_email_id, :string
    add_column :marketing_emails, :resend_status, :string
    add_column :marketing_emails, :webhook_payload, :jsonb

    add_index :marketing_emails, :resend_email_id
    add_index :marketing_emails, :resend_status
  end
end
