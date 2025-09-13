class PromotionalEmailJob < ApplicationJob
  queue_as :default

  # If no email_ids are provided, process the first 90 unsent emails.
  def perform(email_ids = nil)
    scope = Outreach::Email.where(email_sent_at: nil)
    scope = scope.where(id: email_ids) if email_ids.present?
    scope.limit(90).find_each do |email|
      send_email(email)
      sleep get_random_delay.seconds
    end
  end

  private

  def send_email(email)
    PromotionalMailer.cold_email_outreach(email.email, email.first_name, email.company).deliver_now
    email.update(email_sent_at: Time.current)
  end

  def get_random_delay
    return 0 if Rails.env.development?

    rand(5..20)
  end
end
