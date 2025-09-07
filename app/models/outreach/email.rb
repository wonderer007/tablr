require "csv"

class Outreach::Email < ApplicationRecord
  validates :email, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    %w[company created_at email email_sent_at first_name id last_name updated_at]
  end

  # Import Outreach::Email records from a CSV file.
  # Expected headers: first_name,last_name,email,company
  # Returns a hash with counts: { created:, updated:, errors: }
  def self.import_csv(file)
    created_count = 0
    updated_count = 0
    error_count = 0

    CSV.foreach(file.path, headers: true) do |row|
      attrs = {
        first_name: row["First Name"]&.to_s&.strip,
        last_name: row["Last Name"]&.to_s&.strip,
        email: row["Email"]&.to_s&.strip&.downcase,
        company: row["Company"]&.to_s&.strip
      }

      # Skip rows without an email
      next unless attrs[:email].present?

      record = find_or_initialize_by(email: attrs[:email])
      is_new_record = record.new_record?
      record.assign_attributes(attrs.except(:email))

      if record.save
        if is_new_record
          created_count += 1
        else
          updated_count += 1
        end
      else
        error_count += 1
      end
    end

    PromotionalEmailJob.perform_later

    { created: created_count, updated: updated_count, errors: error_count }
  end
end
