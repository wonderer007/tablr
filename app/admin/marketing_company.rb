ActiveAdmin.register Marketing::Company do
  menu label: "Marketing Companies"

  permit_params :name, :linkedin_url, :address, :city, :state, :country, :phone, :google_map_url, :business_id

  member_action :create_business, method: :post do
    company = resource

    if company.google_map_url.blank?
      redirect_to resource_path(company), alert: "No Google Map URL present for this company."
      return
    end

    business = Business.find_or_initialize_by(url: company.google_map_url)
    business.status = :created
    business.business_type = :google_place
    business.test = true
    business.plan = :free

    if business.save
      company.update(business: business)
      # Set payment_approved, onboarding_completed and plan on business
      business.update!(payment_approved: true, onboarding_completed: true, plan: :pro)
      # Create a test user for the business
      random_password = SecureRandom.hex(10)
      business.users.create!(
        email: "testuser#{business.id}@tablr.io",
        first_name: "Test",
        last_name: "User",
        password: random_password,
        password_confirmation: random_password
      )
      Apify::SyncBusinessJob.perform_later(business_id: business.id)
      redirect_to resource_path(company), notice: "Business created and linked to company."
    else
      redirect_to resource_path(company), alert: "Failed to create business: #{business.errors.full_messages.to_sentence}"
    end
  end

  member_action :send_marketing_email, method: :post do
    company = resource
    Marketing::EmailSender.send_for_company(company)

    redirect_to admin_marketing_company_path(company), notice: "Email sent successfully"
  end

  member_action :generate_ai_email, method: :post do
    company = resource
    contact = company.marketing_contacts.first

    if contact.blank?
      redirect_to admin_marketing_company_path(company), alert: "No marketing contact found for this company."
      return
    end

    intro_sentences = default_intro_sentences_for(company)
    ai_generated_intro = RephraseSentences.new(sentences: intro_sentences).call

    if ai_generated_intro.blank?
      redirect_to admin_marketing_company_path(company), alert: "Failed to generate AI content."
      return
    end

    draft_email = company.marketing_emails.where(status: 'draft').first_or_initialize
    draft_email.ai_generated_intro = ai_generated_intro

    if draft_email.save
      redirect_to admin_marketing_company_path(company), notice: "AI generated introduction added to draft."
    else
      redirect_to admin_marketing_company_path(company), alert: "Failed to generate AI content: #{draft_email.errors.full_messages.join(', ')}"
    end
  rescue StandardError => e
    redirect_to admin_marketing_company_path(company), alert: "Failed to generate AI content: #{e.message}"
  end

  member_action :find_google_map_place, method: :post do
    company = resource
    FindGoogleMapJob.perform_later(company.id)
    redirect_to admin_marketing_company_path(company), notice: "Google Map Place finding job started"
  end

  filter :name
  filter :linkedin_url
  filter :city
  filter :state
  filter :country
  filter :business_id
  filter :updated_at

  controller do
    def scoped_collection
      super
        .left_joins(:marketing_contacts)
        .select("marketing_companies.*, COUNT(marketing_contacts.id) AS contacts_count")
        .group("marketing_companies.id")
    end

    private

    def default_intro_sentences_for(company)
      insights = Marketing::ReviewInsights.for_business(company.business)
      customer_complains = insights[:customer_complains]
      customer_suggestions = insights[:customer_suggestions]

      company_name = company.name.to_s.downcase.split.map(&:titleize).join(" ").gsub(".", "")

      introduction = if company.business.rating.to_f >= 4.5
        "With a #{company.business.rating} rating, #{company_name} is clearly winning customers over."
      elsif company.business.rating.to_f >= 4.0
        "#{company_name}'s #{company.business.rating} rating is solid—there's room to make it even better."
      else
        "At #{company.business.rating}, #{company_name} has an opportunity to turn things around."
      end

      complain_sentence = customer_complains.any? ? "However, customers complains about #{customer_complains.first(2).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')} needs your attention, potentially impacting repeats." : nil
      suggestion_sentence = customer_suggestions.any? ? "Additionally, customers suggestions for #{customer_suggestions.first(2).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')} are a great opportunity to improve your business." : nil

      [
        introduction,
        complain_sentence,
        suggestion_sentence
      ].compact
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column "Contacts", sortable: "contacts_count" do |company|
      company.respond_to?(:contacts_count) ? company.contacts_count : company.marketing_contacts.count
    end
    column 'Emails' do |company|
      company.marketing_emails.where(status: 'sent').count
    end    
    column :city
    column :country

    column :business
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
      if resource.google_map_url.present? && resource.business.blank?
        row("Create Business") do |company|
          button_to "Create Business", create_business_admin_marketing_company_path(company), method: :post
        end
      elsif resource.google_map_url.blank?
        row("Find Google Map Place") do |company|
          button_to "Find Google Map Place", find_google_map_place_admin_marketing_company_path(company), method: :post
        end
      end
      row :business
      row :reviews_count do |company|
        company&.business&.reviews&.count
      end
      row :total_reviews do |company|
        company&.business&.data&.dig('reviewsCount') || 0
      end
      row :rating do |company|
        company&.business&.rating&.round(1)
      end
      row :test do |company|
        company&.business&.test?
      end
      row :first_inference_completed do |company|
        company&.business&.first_inference_completed?
      end
      row :created_at
      row :updated_at
    end

    panel "Marketing Email Preview" do
      render 'marketing_email_preview', company: resource if resource&.business&.first_inference_completed? && resource&.marketing_contacts&.any?
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
      f.input :business_id
    end
    f.actions
  end

  batch_action :find_google_map_place do |ids|
    companies = Marketing::Company.where(id: ids)
    companies.each do |company|
      FindGoogleMapJob.perform_later(company.id)
    end
    redirect_back(fallback_location: request.referer, notice: "Google Map Place finding jobs started for #{companies.count} companies")
  end

  batch_action :send_marketing_emails do |ids|
    companies = Marketing::Company.where(id: ids)
    sent_count = 0

    companies.each do |company|
      Marketing::EmailSender.send_for_company(company)
      sent_count += 1
    end

    redirect_to admin_marketing_companies_path, notice: "Marketing emails sent successfully for #{sent_count} compan#{sent_count == 1 ? 'y' : 'ies'}"
  end
end
