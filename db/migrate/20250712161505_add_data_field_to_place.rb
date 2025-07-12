class AddDataFieldToPlace < ActiveRecord::Migration[7.2]
  def change
    add_column :places, :data, :jsonb
  end
end
