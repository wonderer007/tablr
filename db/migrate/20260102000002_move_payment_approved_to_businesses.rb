# frozen_string_literal: true

class MovePaymentApprovedToBusinesses < ActiveRecord::Migration[7.2]
  def up
    # Add payment_approved to businesses
    add_column :businesses, :payment_approved, :boolean, default: false

    # Migrate existing data: if any user has payment_approved, set it on the business
    execute <<-SQL
      UPDATE businesses
      SET payment_approved = true
      WHERE id IN (
        SELECT DISTINCT business_id
        FROM users
        WHERE payment_approved = true AND business_id IS NOT NULL
      )
    SQL

    # Remove payment_approved from users
    remove_column :users, :payment_approved
  end

  def down
    # Add payment_approved back to users
    add_column :users, :payment_approved, :boolean, default: false

    # Migrate data back: set payment_approved on first user of each business
    execute <<-SQL
      UPDATE users
      SET payment_approved = true
      WHERE id IN (
        SELECT MIN(u.id)
        FROM users u
        INNER JOIN businesses b ON u.business_id = b.id
        WHERE b.payment_approved = true
        GROUP BY u.business_id
      )
    SQL

    # Remove payment_approved from businesses
    remove_column :businesses, :payment_approved
  end
end

