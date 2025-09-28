class ChangePlaceUrlUniqueness < ActiveRecord::Migration[7.2]
  def change
    remove_index :places, :url
    add_column :places, :test, :boolean, default: false

    add_index :places, :url
    add_index :places, [:url, :test], unique: true
  end
end
