class PromotionalMailerPreview < ActionMailer::Preview
  def cold_email_outreach
    PromotionalMailer.cold_email_outreach(
      "john.doe@example.com",
      "John Doe",
      "Bella Vista Restaurant"
    )
  end
end
