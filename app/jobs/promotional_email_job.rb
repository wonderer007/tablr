class PromotionalEmailJob < ApplicationJob
  queue_as :default

  # If no email_ids are provided, process the first 90 unsent emails.
  def perform(email_ids = nil)
    scope = Marketing::Contact.where(email_sent_at: nil)
    scope = scope.where(id: email_ids) if email_ids.present?
    scope.limit(95).each_with_index do |email, index|
      send_email(email, index)
      sleep get_random_delay.seconds
    end
  end

  private

  def send_email(email, index)
    if index % 2 == 0
      PromotionalMailer.hidden_patterns_in_reviews(email.email, email.first_name, email.company).deliver_now
    else
      PromotionalMailer.analyzing_reviews_pattern(email.email, email.first_name, email.company).deliver_now
    end
    email.update(email_sent_at: Time.current)
  end

  def get_random_delay
    return 0 if Rails.env.development?

    rand(5..20)
  end
end
