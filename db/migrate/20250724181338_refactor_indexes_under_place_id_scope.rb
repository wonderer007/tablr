class RefactorIndexesUnderPlaceIdScope < ActiveRecord::Migration[7.2]
  def change
    remove_index :categories, :name
    remove_index :keywords, :place_id
    add_index :categories, [:place_id, :name], unique: true

    remove_index :reviews, :external_review_id
    add_index :reviews, [:place_id, :external_review_id], unique: true
  end
end
