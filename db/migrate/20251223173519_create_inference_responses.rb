class CreateInferenceResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :inference_responses do |t|
      t.references :place, null: false, foreign_key: true
      t.jsonb :response
      t.timestamps
    end
  end
end
