class Outreach::Email < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    %w[company created_at email email_sent_at first_name id last_name updated_at]
  end
end
