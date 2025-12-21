ActiveAdmin.register Place do
  menu label: "Places"

  permit_params :name, :url, :data

  filter :name
  filter :status
  filter :rating
  filter :place_actor_run_id
  filter :review_actor_run_id
  filter :first_inference_completed
  filter :test

  index do
    selectable_column
    id_column
    column :name
    column :status
    column :rating
    column :first_inference_completed
    column :test
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row "URL" do |place|
        link_to "Google Map", place.url, target: "_blank"
      end
      row :status
      row :rating
      row :first_inference_completed
      row :test
      row "Place Actor Run ID" do |place|
        link_to place.place_actor_run_id, "https://console.apify.com/actors/#{Place::ACTOR_ID}/runs/#{place.place_actor_run_id}#output", target: "_blank" if place.place_actor_run_id.present?
      end
      row "Review Actor Run ID" do |place|
        link_to place.review_actor_run_id, "https://console.apify.com/actors/#{Review::ACTOR_ID}/runs/#{place.review_actor_run_id}#output", target: "_blank" if place.review_actor_run_id.present?
      end
      row "Reviews Count" do |place|
        place.reviews.count
      end
      row "Total Reviews" do |place|
        place&.data&.dig('reviewsCount') || 0
      end
      row "Users Count" do |place|
        place.users.count
      end
      row :created_at
      row :updated_at
    end

    panel "Users" do
      table_for place.users.limit(10) do
        column :id
        column :email
        column :first_name
        column :last_name
        column :created_at
      end
    end

    panel "Review Analytics" do
      render 'review_analytics', place: place
    end
  end

end
