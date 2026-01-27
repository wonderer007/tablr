class AddTypeInBusiness < ActiveRecord::Migration[7.2]
  def change
    add_column :businesses, :type, :integer, default: 0
    add_index :businesses, :type
  end
end
