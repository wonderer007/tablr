class CreateDemoRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :demo_requests do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :restaurant_name
      t.string :google_map_url

      t.timestamps
    end
  end
end
