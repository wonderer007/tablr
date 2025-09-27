require "csv"

class Outreach::Email < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :company, presence: true
  validates :first_name, presence: true

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
        company: row["Company Name"]&.to_s&.strip,
        email_confidence: row["Email Confidence"]&.to_s&.strip,
        secondary_email: row["Secondary Email"]&.to_s&.strip,
        primary_email_last_verified_at: row["Primary Email Last Verified At"]&.to_s&.strip,
        no_of_employees: row["# Employees"]&.to_s&.strip,
        industry: row["Industry"]&.to_s&.strip,
        linkedin_url: row["Person Linkedin Url"]&.to_s&.strip,
        company_linkedin_url: row["Company Linkedin Url"]&.to_s&.strip,
        website: row["Website"]&.to_s&.strip,
        twitter_url: row["Twitter Url"]&.to_s&.strip,
        city: row["City"]&.to_s&.strip,
        country: row["Country"]&.to_s&.strip,
        company_address: row["Company Address"]&.to_s&.strip,
        company_city: row["Company City"]&.to_s&.strip,
        company_state: row["Company State"]&.to_s&.strip,
        company_country: row["Company Country"]&.to_s&.strip,
        company_phone: row["Company Phone"]&.to_s&.strip,
        annual_revenue: row["Annual Revenue"]&.to_s&.strip
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

    { created: created_count, updated: updated_count, errors: error_count }
  end
end
