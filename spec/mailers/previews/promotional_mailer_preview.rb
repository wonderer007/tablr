class PromotionalMailerPreview < ActionMailer::Preview
  def cold_email_outreach
    PromotionalMailer.cold_email_outreach(contact)
  end

  def hidden_patterns_in_reviews
    PromotionalMailer.hidden_patterns_in_reviews(contact)
  end

  def analyzing_reviews_pattern
    PromotionalMailer.analyzing_reviews_pattern(contact)
  end

  private
  def contact
    # @contact ||= Marketing::Contact.order("RANDOM()")&.first || FactoryBot.create(:marketing_contact)
    @contact ||= Marketing::Contact.find(27)
  end
end
