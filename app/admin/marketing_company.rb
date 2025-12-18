ActiveAdmin.register Marketing::Company do
  menu label: "Marketing Companies"

  permit_params :name, :linkedin_url, :address, :city, :state, :country, :phone, :google_map_url, :place_id

  member_action :create_place, method: :post do
    company = resource

    if company.google_map_url.blank?
      redirect_to resource_path(company), alert: "No Google Map URL present for this company."
      return
    end

    place = Place.find_or_initialize_by(url: company.google_map_url)
    place.status = :created
    place.test = true

    if place.save
      company.update(place: place)
      random_password = SecureRandom.hex(10)
      place.users.create!(
        email: "testuser#{place.id}@tablr.io",
        first_name: "Test",
        last_name: "User",
        password: random_password,
        password_confirmation: random_password,
        payment_approved: true
      )
      Apify::SyncPlaceJob.perform_later(place_id: place.id)
      redirect_to resource_path(company), notice: "Place created and linked to company."
    else
      redirect_to resource_path(company), alert: "Failed to create place: #{place.errors.full_messages.to_sentence}"
    end
  end

  member_action :send_marketing_email, method: :post do
    company = resource
    draft_email = company.marketing_emails.where(status: 'draft').first

    company.marketing_contacts.where(unsubscribed: false).each do |contact|
      if draft_email.present?

        if draft_email.marketing_contact.id == contact.id
          draft_email.update(sent_at: Time.current, status: "sent")
          PromotionalMailer.cold_email_outreach(contact, custom_body: draft_email.body, custom_subject: draft_email.subject).deliver_later
        else
          email = Marketing::Email.create(
            marketing_contact: contact,
            subject: draft_email.subject,
            body: draft_email.body,
            sent_at: Time.current,
            status: "sent",
            error_message: nil
          )
          PromotionalMailer.cold_email_outreach(contact, custom_body: email.body, custom_subject: email.subject).deliver_later
        end

      else
        email = Marketing::Email.create(
          marketing_contact: contact,
          subject: "Unlock 22% Revenue Growth from #{company.name&.downcase&.split&.map(&:titleize)&.join(" ")} Reviews - Free Report Inside",
          body: PromotionalMailer.cold_email_outreach(contact).body.to_s,
          sent_at: Time.current,
          status: "sent",
          error_message: nil
        )
        PromotionalMailer.cold_email_outreach(contact).deliver_later
      end
    end

    redirect_to admin_marketing_company_path(company), notice: "Email sent successfully"
  end

  member_action :save_draft, method: :post do
    company = resource

    contact = company.marketing_contacts.first

    if contact.blank?
      redirect_to admin_marketing_company_path(company), alert: "No marketing contact found for this company."
      return
    end

    # Find existing draft or create new one
    draft_email = company.marketing_emails.where(status: 'draft').first_or_initialize
    draft_email.marketing_contact = contact
    draft_email.subject = params[:subject] if params[:subject].present?
    draft_email.body = params[:body] if params[:body].present?
    draft_email.status = "draft"
    draft_email.error_message = nil

    if draft_email.save
      redirect_to admin_marketing_company_path(company), notice: "Draft saved successfully"
    else
      redirect_to admin_marketing_company_path(company), alert: "Failed to save draft: #{draft_email.errors.full_messages.join(', ')}"
    end
  end

  member_action :reset_draft, method: :post do
    company = resource

    draft_email = company.marketing_emails.where(status: 'draft').first
    draft_email&.destroy

    redirect_to admin_marketing_company_path(company), notice: "Email content reset to default"
  end

  filter :name
  filter :linkedin_url
  filter :city
  filter :state
  filter :country
  filter :place_id
  filter :updated_at

  index do
    selectable_column
    id_column
    column :name
    column "Contacts" do |company|
      company.marketing_contacts.count
    end
    column :city
    column :country
    column 'Emails' do |company|
      sent_count = company.marketing_emails.where(status: 'sent').count
      draft_count = company.marketing_emails.where(status: 'draft').count
      "#{sent_count} sent, #{draft_count} draft"
    end
    column :place
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :linkedin_url do |company|
        link_to company.linkedin_url, company.linkedin_url, target: "_blank" if company.linkedin_url.present?
      end
      row :address
      row :city
      row :state
      row :country
      row :phone
      row :google_map_url do |company|
        link_to company.google_map_url, company.google_map_url, target: "_blank" if company.google_map_url.present?
      end
      if resource.google_map_url.present? && resource.place.blank?
        row("Create Place") do |company|
          button_to "Create Place", create_place_admin_marketing_company_path(company), method: :post
        end
      end
      row :place
      row :created_at
      row :updated_at
    end

    panel "Marketing Email Preview" do
      render 'marketing_email_preview', company: resource if resource.place.present? && resource.place.first_inference_completed?
    end

    panel "Contacts" do
      table_for resource.marketing_contacts do
        column :name do |contact|
          "#{contact.first_name} #{contact.last_name}"
        end
        column :email
        column "Last Email Sent At" do |contact|
          contact.marketing_emails.where(status: 'sent').last&.sent_at&.strftime("%B %d, %Y %I:%M %p")
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :linkedin_url
      f.input :address
      f.input :city
      f.input :state
      f.input :country
      f.input :phone
      f.input :google_map_url
      f.input :place_id
    end
    f.actions
  end

  batch_action :send_marketing_emails do |ids|
    companies = Marketing::Company.where(id: ids)
    sent_count = 0

    companies.each do |company|
      draft_email = company.marketing_emails.where(status: 'draft').first

      company.marketing_contacts.where(unsubscribed: false).each do |contact|
        if draft_email.present?
          if draft_email.marketing_contact.id == contact.id
            draft_email.update(sent_at: Time.current, status: "sent")
            PromotionalMailer.cold_email_outreach(contact, custom_body: draft_email.body, custom_subject: draft_email.subject).deliver_later
          else
            email = Marketing::Email.create(
              marketing_contact: contact,
              subject: draft_email.subject,
              body: draft_email.body,
              sent_at: Time.current,
              status: "sent",
              error_message: nil
            )
            PromotionalMailer.cold_email_outreach(contact, custom_body: email.body, custom_subject: email.subject).deliver_later
          end
        else
          email = Marketing::Email.create(
            marketing_contact: contact,
            subject: "Unlock 22% Revenue Growth from #{company.name&.downcase&.split&.map(&:titleize)&.join(" ")} Reviews - Free Report Inside",
            body: PromotionalMailer.cold_email_outreach(contact).body.to_s,
            sent_at: Time.current,
            status: "sent",
            error_message: nil
          )
          PromotionalMailer.cold_email_outreach(contact).deliver_later
        end
      end

      sent_count += 1
    end

    redirect_to admin_marketing_companies_path, notice: "Marketing emails sent successfully for #{sent_count} compan#{sent_count == 1 ? 'y' : 'ies'}"
  end
end
