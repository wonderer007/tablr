class CreateSuggestions < ActiveRecord::Migration[7.2]
  def change
    create_table :suggestions do |t|
      t.string :text
      t.references :category, null: false, foreign_key: true
      t.references :review, null: false, foreign_key: true

      t.timestamps
    end
  end
end
