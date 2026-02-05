ActiveAdmin.register Marketing::Contact do
  menu label: "Marketing Contacts"

  permit_params :first_name, :last_name, :email, :company_name, :company_id, :secondary_email, :business_id

  member_action :verify_email, method: :post do
    result = Marketing::EmailVerifier.new(resource.email).call

    if result[:error]
      redirect_to resource_path(resource), alert: "Verification failed: #{result[:error]}"
    else
      resource.update!(
        email_status: result[:email_status],
        never_bounce_response: result[:never_bounce_response]
      )
      redirect_to resource_path(resource), notice: "Email verified: #{result[:email_status]}"
    end
  end

  # CSV Import UI in the index sidebar
  sidebar "Import Marketing Contacts", only: :index do
    para "Upload a CSV with headers: first_name,last_name,email,company"
    div do
      form action: import_admin_marketing_contacts_path, method: :post, enctype: "multipart/form-data" do |f|
        input type: "hidden", name: request_forgery_protection_token.to_s, value: form_authenticity_token
        input type: "file", name: "file", accept: ".csv"
        br
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


  # Batch action to bulk update company_id
  batch_action :update_company_id, form: {
    company_id: :text
  } do |ids, inputs|
    contacts = Marketing::Contact.where(id: ids)
    updated_count = 0

    contacts.each do |contact|
      if contact.update(company_id: inputs[:company_id])
        updated_count += 1
      end
    end

    redirect_to collection_path, notice: "#{updated_count} of #{ids.count} marketing contacts updated with company_id: #{inputs[:company_id]}"
  end

  filter :first_name
  filter :last_name
  filter :email
  filter :email_status, as: :select, collection: %w[valid invalid disposable accept_all unknown]
  filter :company_name
  filter :company_id
  filter :secondary_email
  filter :created_at

  index do
    selectable_column
    id_column
    column :name do |contact|
      "#{contact.first_name} #{contact.last_name}"
    end
    column :email
    column :email_status
    column :company_name
    column :website do |contact|
      link_to contact.website, contact.website, target: "_blank" if contact.website.present?
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :first_name
      row :last_name
      row :email
      row :email_status
      row :never_bounce_response do |contact|
        if contact.never_bounce_response.present?
          pre { contact.never_bounce_response.to_json }
        end
      end
      unless resource.email_verified?
        row "Verify Email" do |contact|
          button_to "Verify Email", verify_email_admin_marketing_contact_path(contact), method: :post
        end
      end
      row :company_name
      row :company do |contact|
        if contact.company
          link_to contact.company.name, admin_marketing_company_path(contact.company)
        end
      end
      row :business
      row :email_confidence
      row :primary_email_last_verified_at
      row :no_of_employees
      row :industry
      row "Last Email Sent At" do |contact|
        contact.marketing_emails.where(status: 'sent').last&.sent_at&.strftime("%B %d, %Y %I:%M %p")
      end      
      row :linkedin_url
      row :annual_revenue
      row :secondary_email
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :company, as: :select, collection: Marketing::Company.all.pluck(:name, :id)
      f.input :email_confidence
      f.input :primary_email_last_verified_at
      f.input :no_of_employees
      f.input :industry
      f.input :linkedin_url
      f.input :website
      f.input :twitter_url
      f.input :city
      f.input :country
      f.input :annual_revenue
      f.input :secondary_email
    end
    f.actions
  end
end
