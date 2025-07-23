class AddPlaceIdInTables < ActiveRecord::Migration[7.2]
  def change
    add_reference :categories, :place, null: false, foreign_key: true
    add_reference :keywords, :place, null: false, foreign_key: true
    add_reference :complains, :place, null: false, foreign_key: true
    add_reference :suggestions, :place, null: false, foreign_key: true
  end
end
