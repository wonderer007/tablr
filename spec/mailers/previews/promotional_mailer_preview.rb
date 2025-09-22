class PromotionalMailerPreview < ActionMailer::Preview
  def cold_email_outreach
    PromotionalMailer.cold_email_outreach(
      "john.doe@example.com",
      "John Doe",
      "Bella Vista Restaurant"
    )
  end

  def hidden_patterns_in_reviews
    PromotionalMailer.hidden_patterns_in_reviews(
      "john.doe@example.com",
      "John Doe",
      "Bella Vista Restaurant"
    )
  end

  def analyzing_reviews_pattern
    PromotionalMailer.analyzing_reviews_pattern(
      "john.doe@example.com",
      "John Doe",
      "Bella Vista Restaurant"
    )
  end
end
