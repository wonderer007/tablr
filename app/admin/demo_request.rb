ActiveAdmin.register DemoRequest do
  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :email
    column :restaurant_name
    column :created_at
    actions
  end
end
