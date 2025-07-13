class CreateKeywords < ActiveRecord::Migration[7.2]
  def change
    create_table :keywords do |t|
      t.references :review, null: false, foreign_key: true
      t.string :name
      t.integer :sentiment
      t.float :sentiment_score
      t.references :category, null: false, foreign_key: true
      t.boolean :is_dish, default: false

      t.timestamps
    end
  end
end
