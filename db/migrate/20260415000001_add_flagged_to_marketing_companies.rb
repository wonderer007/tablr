class AddFlaggedToMarketingCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :marketing_companies, :flagged, :boolean, default: false, null: false
  end
end
