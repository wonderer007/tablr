class AddAiGeneratedContentToMarketingCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_companies, :ai_generated_content, :text
  end
end
