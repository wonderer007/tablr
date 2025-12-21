class AddAiGeneratedIntroToMarketingEmails < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_emails, :ai_generated_intro, :text
  end
end

