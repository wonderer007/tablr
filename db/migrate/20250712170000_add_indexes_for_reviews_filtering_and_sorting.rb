class AddIndexesForReviewsFilteringAndSorting < ActiveRecord::Migration[7.2]
  def change
    # Indexes for filtering
    add_index :reviews, :stars
    add_index :reviews, :food_rating
    add_index :reviews, :service_rating
    add_index :reviews, :atmosphere_rating
    add_index :reviews, :published_at
    
    # Composite indexes for common filter combinations
    add_index :reviews, [:place_id, :stars]
    add_index :reviews, [:place_id, :published_at]

    # Text search index (if using PostgreSQL full-text search)
    enable_extension 'pg_trgm'
    add_index :reviews, :text, using: :gin, opclass: :gin_trgm_ops
  end
end 