class CreatePlaces < ActiveRecord::Migration[7.2]
  def change
    create_table :places do |t|
      t.string :name
      t.string :place_actor_run_id
      t.string :review_actor_run_id
      t.datetime :review_synced_at
      t.datetime :place_synced_at
      t.integer :status
      t.string :url
      t.jsonb :data

      t.timestamps
    end

    add_index :places, :url, unique: true
  end
end
