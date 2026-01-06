class PromotionalEmailJob < ApplicationJob
  queue_as :default

  # If no email_ids are provided, process the first 90 unsent emails.
  def perform(email_ids = nil)
    scope = Marketing::Contact.where(email_sent_at: nil).where.missing(:marketing_emails)
    scope = scope.where(id: email_ids) if email_ids.present?
    scope.limit(95).each_with_index do |contact, index|
      send_email(contact, index)
      sleep get_random_delay.seconds
    end
  end

  private

  def send_email(contact, index)
    PromotionalMailer.demo_invite(contact).deliver_now
    contact.update(email_sent_at: Time.current)
  end

  def get_random_delay
    return 0 if Rails.env.development?

    rand(5..20)
  end
end
