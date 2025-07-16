class AddRatingInPlace < ActiveRecord::Migration[7.2]
  def change
    add_column :places, :rating, :float
  end
end
