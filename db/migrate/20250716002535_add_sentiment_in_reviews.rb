class AddSentimentInReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :sentiment, :integer
  end
end
