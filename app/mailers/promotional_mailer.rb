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
    @company_name = contact.company.name.downcase.split.map(&:titleize).join(" ").gsub(".", "")
    @recipient_email = contact.email
    @place = contact.company.place
    @company = contact.company
    @email = contact.email
    @ai_generated_intro = ai_generated_intro
    insights = Marketing::ReviewInsights.for_place(@place)
    @positive_categories = insights[:positive_categories]
    @feedback = insights[:feedback]

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
