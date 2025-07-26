class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.string :text, null: false
      t.boolean :read, default: false
      t.string :notification_type, null: false
      t.references :place, null: false, foreign_key: true

      t.timestamps
    end
  end
end
