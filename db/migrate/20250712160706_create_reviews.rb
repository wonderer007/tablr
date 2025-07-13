class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :place, null: false, foreign_key: true
      t.jsonb :review_context
      t.string :review_url
      t.string :external_review_id
      t.string :text
      t.integer :stars
      t.integer :likes_count
      t.integer :food_rating
      t.integer :service_rating
      t.integer :atmosphere_rating
      t.datetime :published_at
      t.jsonb :data
      t.boolean :processed, default: false

      t.timestamps
    end

    add_index :reviews, :external_review_id, unique: true
  end
end
