class PromotionalMailer < ApplicationMailer
  default from: "Haider Ali <hello@tablr.io>"

  def cold_email_outreach(recipient_email, recipient_name, company_name)
    @recipient_name = recipient_name
    @company_name = company_name
    @recipient_email = recipient_email

    mail(
      to: recipient_email,
      subject: "How #{company_name} can stop losing customers to bad reviews"
    )
  end
end
