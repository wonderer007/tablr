class PromotionalMailer < ApplicationMailer
  default from: "Haider Ali <mail@tablr.org>"
  include AnalyticsHelper
  include Rails.application.routes.url_helpers

  private

  def recipient_name(contact)
    if contact.first_name.present? && contact.first_name.length > 1
      contact.first_name
    elsif contact.last_name.present? && contact.last_name.length > 1
      contact.last_name
    elsif contact.email.present?
      contact.email.split("@").first
    else
      "there"
    end
  end

  public

  def cold_email_outreach(contact, ai_generated_intro: nil)
    @recipient_name = recipient_name(contact)
    @company_name = contact.company.name.downcase.split.map(&:titleize).join(" ").gsub(".", "")
    @recipient_email = contact.email
    @business = contact.company.business
    @company = contact.company
    @email = contact.email
    @unsubscribe_token = contact.unsubscribe_token
    @ai_generated_intro = ai_generated_intro
    insights = Marketing::ReviewInsights.for_business(@business)
    @customer_suggestions = insights[:customer_suggestions]
    @customer_complains = insights[:customer_complains]

    mail(
      to: contact.email,
      subject: "Unlock 22% Revenue Growth from #{@company_name} Reviews",
      headers: {
        'List-Unsubscribe' => "<#{unsubscribe_url(token: @unsubscribe_token)}>"
      }
    ) do |format|
        format.html
    end
  end

  def demo_invite(contact)
    @recipient_name = recipient_name(contact)
    @email = contact.email
    @unsubscribe_token = contact.unsubscribe_token

    mail(
      to: contact.email,
      subject: "Turn Customer Feedback into Revenue with AI",
      headers: {
        'List-Unsubscribe' => "<#{unsubscribe_url(token: @unsubscribe_token)}>"
      }
    ) do |format|
      format.html
    end
  end

  def send_draft_email(contact, subject:, body:)
    @recipient_name = recipient_name(contact)
    @unsubscribe_token = contact.unsubscribe_token
    @body = body.to_s
              .gsub('{{RECIPIENT_NAME}}', @recipient_name)
              .gsub('{{UNSUBSCRIBE_LINK}}', '<a href="' + unsubscribe_url(token: @unsubscribe_token) + '" target="_blank">Unsubscribe</a>')

    mail(
      to: contact.email,
      subject: subject,
      headers: {
        'List-Unsubscribe' => "<#{unsubscribe_url(token: @unsubscribe_token)}>"
      }
    ) do |format|
      format.html { render 'send_draft_email' }
    end
  end
end
