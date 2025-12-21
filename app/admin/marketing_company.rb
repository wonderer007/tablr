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
  filter :place_id
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
      positive = Hash.new(0)
      negative = Hash.new(0)

      Keyword.positive.each { |keyword| positive[keyword.category_id] += 1 }
      Keyword.negative.each { |keyword| negative[keyword.category_id] += 1 }

      positive_categories =
        if positive.any?
          Category.where(id: positive.map(&:first)).pluck(:name)
        else
          ['Food', 'Service']
        end

      negative_categories =
        if negative.any?
          Category.where(id: negative.map(&:first)).pluck(:name)
        else
          ['Price', 'Timing']
        end

      complains = Complain.group(:category_id).count.sort_by { |category_id, count| -count }
      customer_complains = complains.any? ? Complain.where(category_id: complains.first.first).limit(2).pluck(:text) : []

      suggestions = Suggestion.group(:category_id).count.sort_by { |category_id, count| -count }
      customer_suggestions = suggestions.any? ? Suggestion.where(category_id: suggestions.first.first).limit(2).pluck(:text) : []

      feedback = [customer_suggestions.sample(2), customer_complains.sample(2), negative_categories.first(2)].flatten.compact.uniq

      company_name = company.name.to_s.downcase.split.map(&:titleize).join(" ")

      [
        "I analyzed recent reviews for #{company_name} and found customers love the #{positive_categories.first(2).map(&:downcase).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')}—solid wins to build on.",
        "However, feedback on #{feedback.first(2).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')} needs your attention, potentially impacting repeats."
      ]
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
      elsif resource.google_map_url.blank?
        row("Find Google Map Place") do |company|
          button_to "Find Google Map Place", find_google_map_place_admin_marketing_company_path(company), method: :post
        end
      end
      row :place
      row :reviews_count do |company|
        company&.place&.reviews&.count
      end
      row :total_reviews do |company|
        company&.place&.data&.dig('reviewsCount') || 0
      end
      row :rating do |company|
        company&.place&.rating&.round(1)
      end
      row :test do |company|
        company&.place&.test?
      end
      row :first_inference_completed do |company|
        company&.place&.first_inference_completed?
      end
      row :created_at
      row :updated_at
    end

    panel "Marketing Email Preview" do
      render 'marketing_email_preview', company: resource if resource&.place&.first_inference_completed? && resource&.marketing_contacts&.any?
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
