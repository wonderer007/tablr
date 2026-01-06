class PromotionalMailerPreview < ActionMailer::Preview
  def cold_email_outreach
    PromotionalMailer.cold_email_outreach(contact)
  end

  def demo_invite
    PromotionalMailer.demo_invite(contact)
  end

  private
  def contact
    # @contact ||= Marketing::Contact.order("RANDOM()")&.first || FactoryBot.create(:marketing_contact)
    @contact ||= Marketing::Contact.find(27)
  end
end
