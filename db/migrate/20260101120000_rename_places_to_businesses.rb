class RenamePlacesToBusinesses < ActiveRecord::Migration[7.2]
  def change
    # Rename the main table
    rename_table :places, :businesses

    # Rename place_id columns to business_id in all related tables
    rename_column :categories, :place_id, :business_id
    rename_column :complains, :place_id, :business_id
    rename_column :inference_responses, :place_id, :business_id
    rename_column :keywords, :place_id, :business_id
    rename_column :marketing_companies, :place_id, :business_id
    rename_column :marketing_emails, :place_id, :business_id
    rename_column :notifications, :place_id, :business_id
    rename_column :reviews, :place_id, :business_id
    rename_column :suggestions, :place_id, :business_id
    rename_column :users, :place_id, :business_id

    # Add business_type column for future extensibility
    add_column :businesses, :business_type, :string, default: 'google_place', null: false
    add_index :businesses, :business_type
  end
end

