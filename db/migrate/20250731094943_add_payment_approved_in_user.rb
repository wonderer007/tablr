class AddPaymentApprovedInUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :payment_approved, :boolean, default: false
  end
end
