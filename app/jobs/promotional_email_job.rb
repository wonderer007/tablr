class PromotionalEmailJob < ApplicationJob
  queue_as :default

  def perform
    Outreach::Email.where(email_sent_at: nil).find_each do |email|
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
    rand(5..10)
  end
end
