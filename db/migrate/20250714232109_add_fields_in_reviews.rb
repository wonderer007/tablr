class AddFieldsInReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :name, :string
    add_column :reviews, :image_url, :string
  end
end
