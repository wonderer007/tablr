class PromotionalMailer < ApplicationMailer
  default from: "Haider Ali <hello@tablr.io>"
  include AnalyticsHelper
  include Rails.application.routes.url_helpers

  private

  def recipient_name(contact)
    if contact.first_name.present? && contact.first_name.length > 1
      contact.first_name
    elsif contact.last_name.present? && contact.last_name.length > 1
      contact.last_name
    else
      "Valued Customer"
    end
  end

  public

  def cold_email_outreach(contact, ai_generated_intro: nil)
    @recipient_name = recipient_name(contact)
    @company_name = contact.company.name.downcase.split.map(&:titleize).join(" ")
    @recipient_email = contact.email
    @place = contact.company.place
    @company = contact.company
    @email = contact.email
    @ai_generated_intro = ai_generated_intro

    ActsAsTenant.current_tenant = @place

    positive = Hash.new(0)
    negative = Hash.new(0)

    Keyword.positive.each { |keyword| positive[keyword.category_id] += 1 }
    Keyword.negative.each { |keyword| negative[keyword.category_id] += 1 }

    positive = positive.sort_by { |category_id, count| -1 * count }
    negative = negative.sort_by { |category_id, count| -1 * count }

    if positive.any?
      @positive_categories = Category.where(id: positive.map(&:first)).pluck(:name)
    else
      @positive_categories = ['Food', 'Service']
    end

    if negative.any?
      negative_categories = Category.where(id: negative.map(&:first)).pluck(:name)
    else
      negative_categories = ['Price', 'Timing']
    end

    complains = Complain.group(:category_id).count.sort_by { |category_id, count| -count }

    if complains.any?
      customer_complains = Complain.where(category_id: complains.first.first).limit(2).pluck(:text)
    else
      customer_complains = []
    end

    suggestions = Suggestion.group(:category_id).count.sort_by { |category_id, count| -count }
    if suggestions.any?
      customer_suggestions = Suggestion.where(category_id: suggestions.first.first).limit(2).pluck(:text)
    else
      customer_suggestions = []
    end

    @feedback = [customer_suggestions.sample(2), customer_complains.sample(2), negative_categories.first(2)].flatten.compact.uniq

    mail(
      to: contact.email,
      subject: "Unlock 22% Revenue Growth from #{@company_name} Reviews - Free Report Inside",
      headers: {
        'List-Unsubscribe' => "<#{unsubscribe_url(email: contact.email)}>"
      }
    ) do |format|
        format.html
    end
  end
end
