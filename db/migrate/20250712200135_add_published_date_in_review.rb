class AddPublishedDateInReview < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :published_at, :datetime
    rename_column :reviews, :atmosphere, :atmosphere_rating
  end
end
