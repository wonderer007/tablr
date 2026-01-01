ActiveAdmin.register Business do
  menu label: "Businesses"

  permit_params :name, :url, :data, :business_type

  filter :name
  filter :status
  filter :rating
  filter :business_type
  filter :place_actor_run_id
  filter :review_actor_run_id
  filter :first_inference_completed
  filter :test

  index do
    selectable_column
    id_column
    column :name
    column :business_type
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
      row :business_type
      row "URL" do |business|
        link_to "Google Map", business.url, target: "_blank"
      end
      row :status
      row :rating
      row :first_inference_completed
      row :test
      row "Place Actor Run ID" do |business|
        link_to business.place_actor_run_id, "https://console.apify.com/actors/#{Business::ACTOR_ID}/runs/#{business.place_actor_run_id}#output", target: "_blank" if business.place_actor_run_id.present?
      end
      row "Review Actor Run ID" do |business|
        link_to business.review_actor_run_id, "https://console.apify.com/actors/#{Review::ACTOR_ID}/runs/#{business.review_actor_run_id}#output", target: "_blank" if business.review_actor_run_id.present?
      end
      row "Reviews Count" do |business|
        business.reviews.count
      end
      row "Total Reviews" do |business|
        business&.data&.dig('reviewsCount') || 0
      end
      row "Users Count" do |business|
        business.users.count
      end
      row :created_at
      row :updated_at
    end

    panel "Users" do
      table_for business.users.limit(10) do
        column :id
        column :email
        column :first_name
        column :last_name
        column :created_at
      end
    end

    panel "Review Analytics" do
      render 'review_analytics', business: business
    end
  end

end

