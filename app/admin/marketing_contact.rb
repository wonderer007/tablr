ActiveAdmin.register Marketing::Contact do
  menu label: "Marketing Contacts"

  permit_params :first_name, :last_name, :email, :company, :secondary_email, :google_map_url

  # CSV Import UI in the index sidebar
  sidebar "Import Marketing Contacts", only: :index do
    para "Upload a CSV with headers: first_name,last_name,email,company"
    div do
      form action: import_admin_marketing_contacts_path, method: :post, enctype: "multipart/form-data" do |f|
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
        result = Marketing::Contact.import_csv(params[:file])
        redirect_to admin_marketing_contacts_path, notice: "Import complete: #{result[:created]} created, #{result[:updated]} updated, #{result[:errors]} errors"
      rescue => e
        redirect_to admin_marketing_contacts_path, alert: "Import failed: #{e.message}"
      end
    else
      redirect_to admin_marketing_contacts_path, alert: "Please choose a CSV file to upload."
    end
  end

  member_action :create_place, method: :post do
    contact = resource

    if contact.google_map_url.blank?
      redirect_to resource_path(contact), alert: "No Google Map URL present for this contact."
      return
    end

    place = Place.find_or_initialize_by(url: contact.google_map_url)
    place.status = :created
    place.test = true

    if place.save
      contact.update(place: place)
      random_password = SecureRandom.hex(10)
      place.users.create!(
        email: "testuser#{contact.id}@tablr.io",
        first_name: contact.first_name,
        last_name: contact.last_name,
        password: random_password,
        password_confirmation: random_password,
        payment_approved: true
      )
      Apify::SyncPlaceJob.perform_later(place_id: place.id)
      redirect_to resource_path(contact), notice: "Place created and linked to contact."
    else
      redirect_to resource_path(contact), alert: "Failed to create place: #{place.errors.full_messages.to_sentence}"
    end
  end

  filter :first_name
  filter :last_name
  filter :email
  filter :company
  filter :secondary_email
  filter :created_at

  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :email
    column :secondary_email
    column :company
    column :website
    column :country
    column :place
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
      row :place
      if resource.google_map_url.present? && resource.place.blank?
        row("Create Place") do |contact|
          button_to "Create Place", create_place_admin_marketing_contact_path(contact), method: :post
        end
      end
      row :email_sent_at
      row :email_confidence
      row :primary_email_last_verified_at
      row :no_of_employees
      row :industry
      row :linkedin_url
      row :company_linkedin_url
      row :website
      row :twitter_url
      row :city
      row :country
      row :company_address
      row :company_city
      row :company_state
      row :company_country
      row :company_phone
      row :annual_revenue
      row :secondary_email
      row :google_map_url
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
      f.input :email_confidence
      f.input :primary_email_last_verified_at
      f.input :no_of_employees
      f.input :industry
      f.input :linkedin_url
      f.input :company_linkedin_url
      f.input :website
      f.input :twitter_url
      f.input :city
      f.input :country
      f.input :company_address
      f.input :company_city
      f.input :company_state
      f.input :company_country
      f.input :company_phone
      f.input :annual_revenue
      f.input :secondary_email
      f.input :google_map_url
    end
    f.actions
  end
end
