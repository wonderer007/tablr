ActiveAdmin.register Outreach::Email do
  menu label: "Outreach Emails"

  permit_params :first_name, :last_name, :email, :company

  # CSV Import UI in the index sidebar
  sidebar "Import Outreach Emails", only: :index do
    para "Upload a CSV with headers: first_name,last_name,email,company"
    div do
      form action: import_admin_outreach_emails_path, method: :post, enctype: "multipart/form-data" do |f|
        input type: "hidden", name: request_forgery_protection_token.to_s, value: form_authenticity_token
        input type: "file", name: "file", accept: ".csv"
        br
        input type: "submit", value: "Import CSV"
      end
    end
  end

  # Handle CSV upload
  collection_action :import, method: :post do
    if params[:file].present?
      begin
        result = Outreach::Email.import_csv(params[:file])
        redirect_to admin_outreach_emails_path, notice: "Import complete: #{result[:created]} created, #{result[:updated]} updated, #{result[:errors]} errors"
      rescue => e
        redirect_to admin_outreach_emails_path, alert: "Import failed: #{e.message}"
      end
    else
      redirect_to admin_outreach_emails_path, alert: "Please choose a CSV file to upload."
    end
  end

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
