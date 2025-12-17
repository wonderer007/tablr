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
    column 'Emails' do |place|
      sent_count = place.marketing_emails.where(status: 'sent').count
      draft_count = place.marketing_emails.where(status: 'draft').count
      "#{sent_count} sent, #{draft_count} draft"
    end
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
      row "Users Count" do |place|
        place.users.count
      end
      row :created_at
      row :updated_at
    end

    panel "Marketing Email Preview" do
      render 'marketing_email_preview', place: place
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

    place "M"
    panel "Marketing Contacts" do
      table_for place.marketing_contacts do
        column :id
        column :name do |contact|
          "#{contact.first_name} #{contact.last_name}"
        end
        column :email
        column :company
        column :unsubscribed
        column :email_sent_at do |contact|
          contact.marketing_emails.where(status: 'sent').order(sent_at: :desc).first&.sent_at
        end
      end
    end
    panel "Review Analytics" do
      render 'review_analytics', place: place
    end
  end

  member_action :send_marketing_email, method: :post do
    place = resource
    draft_email = place.marketing_emails.where(status: 'draft').first

    place.marketing_contacts.where(unsubscribed: false).each do |contact|
      if draft_email.present?

        if draft_email.marketing_contact.id == contact.id
          draft_email.update(sent_at: Time.current, status: "sent")
          PromotionalMailer.cold_email_outreach(contact, custom_body: draft_email.body, custom_subject: draft_email.subject).deliver_later
        else
          email = PromotionalMailer.cold_email_outreach(contact)

          email = Marketing::Email.create(
            place: place,
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
          place: place,
          marketing_contact: contact,
          subject: "Unlock 22% Revenue Growth from #{contact.company.downcase.split.map(&:titleize).join(" ")} Reviews - Free Report Inside",
          body: PromotionalMailer.cold_email_outreach(contact).body.to_s,
          sent_at: Time.current,
          status: "sent",
          error_message: nil
        )
        PromotionalMailer.cold_email_outreach(contact).deliver_later
      end
    end

    redirect_to admin_place_path(place), notice: "Email sent successfully"
  end

  member_action :save_draft, method: :post do
    place = resource

    contact = place.marketing_contacts.first

    if contact.blank?
      redirect_to admin_place_path(place), alert: "No marketing contact found for this place."
      return
    end

    # Find existing draft or create new one
    draft_email = place.marketing_emails.where(status: 'draft').first_or_initialize
    draft_email.marketing_contact = contact
    draft_email.subject = params[:subject]
    draft_email.body = params[:body]
    draft_email.status = "draft"
    draft_email.error_message = nil

    if draft_email.save
      redirect_to admin_place_path(place), notice: "Draft saved successfully"
    else
      redirect_to admin_place_path(place), alert: "Failed to save draft: #{draft_email.errors.full_messages.join(', ')}"
    end
  end

  member_action :reset_draft, method: :post do
    place = resource

    draft_email = place.marketing_emails.where(status: 'draft').first
    draft_email&.destroy

    redirect_to admin_place_path(place), notice: "Email content reset to default"
  end

  batch_action :send_marketing_emails do |ids|
    places = Place.where(id: ids)
    sent_count = 0

    places.each do |place|
      draft_email = place.marketing_emails.where(status: 'draft').first

      place.marketing_contacts.where(unsubscribed: false).each do |contact|
        if draft_email.present?
          if draft_email.marketing_contact.id == contact.id
            draft_email.update(sent_at: Time.current, status: "sent")
            PromotionalMailer.cold_email_outreach(contact, custom_body: draft_email.body, custom_subject: draft_email.subject).deliver_later
          else
            email = Marketing::Email.create(
              place: place,
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
            place: place,
            marketing_contact: contact,
            subject: "Unlock 22% Revenue Growth from #{contact.company.downcase.split.map(&:titleize).join(" ")} Reviews - Free Report Inside",
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

    redirect_to admin_places_path, notice: "Marketing emails sent successfully for #{sent_count} place#{sent_count == 1 ? '' : 's'}"
  end
end
