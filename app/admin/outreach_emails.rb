ActiveAdmin.register Outreach::Email do
  menu label: "Outreach Emails"

  permit_params :first_name, :last_name, :email, :company

  filter :first_name
  filter :last_name
  filter :email
  filter :company
  filter :created_at

  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :email
    column :company
    column :email_sent_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :first_name
      row :last_name
      row :email
      row :company
      row :email_sent_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :company
      f.input :email_sent_at
    end
    f.actions
  end
end


