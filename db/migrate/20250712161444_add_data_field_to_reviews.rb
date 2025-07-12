class AddDataFieldToReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :data, :jsonb
  end
end
