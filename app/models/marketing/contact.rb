require "csv"

class Marketing::Contact < ApplicationRecord
  self.table_name = "marketing_contacts"
  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true

  belongs_to :company, class_name: "Marketing::Company", optional: true
  has_many :marketing_emails, class_name: "Marketing::Email", foreign_key: "marketing_contact_id", dependent: :destroy

  before_create :generate_unsubscribe_token

  private

  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end

  public

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at email email_sent_at first_name id last_name secondary_email unsubscribed updated_at company_id company_name]
  end

  def self.ransackable_associations(auth_object = nil)
    ["company", "marketing_emails"]
  end

  # Import Marketing::Contact records from a CSV file.
  # Expected headers: first_name,last_name,email,company
  # Returns a hash with counts: { created:, updated:, errors: }
  def self.import_csv(file)
    created_count = 0
    updated_count = 0
    error_count = 0

    CSV.foreach(file.path, headers: true) do |row|
      contact_attrs = {
        first_name: row["First Name"]&.to_s&.strip,
        last_name: row["Last Name"]&.to_s&.strip,
        email: row["Email"]&.to_s&.strip&.downcase,
        email_confidence: row["Email Confidence"]&.to_s&.strip,
        secondary_email: row["Secondary Email"]&.to_s&.strip,
        primary_email_last_verified_at: row["Primary Email Last Verified At"]&.to_s&.strip,
        no_of_employees: row["# Employees"]&.to_s&.strip,
        industry: row["Industry"]&.to_s&.strip,
        linkedin_url: row["Person Linkedin Url"]&.to_s&.strip,
        website: row["Website"]&.to_s&.strip,
        twitter_url: row["Twitter Url"]&.to_s&.strip,
        city: row["City"]&.to_s&.strip,
        country: row["Country"]&.to_s&.strip,
        annual_revenue: row["Annual Revenue"]&.to_s&.strip
      }

      company_attrs = {
        name: row["Company Name"]&.to_s&.strip,
        linkedin_url: row["Company Linkedin Url"]&.to_s&.strip,
        address: row["Company Address"]&.to_s&.strip,
        city: row["Company City"]&.to_s&.strip,
        state: row["Company State"]&.to_s&.strip,
        country: row["Company Country"]&.to_s&.strip,
        phone: row["Company Phone"]&.to_s&.strip,
      }

      # Skip rows without an email
      next unless contact_attrs[:email].present?

      # Find or create company if company name is provided
      company = nil
      if company_attrs[:name].present?
        company = Marketing::Company.find_or_create_by!(name: company_attrs[:name]) do |c|
          c.assign_attributes(company_attrs.except(:name))
        end
        contact_attrs[:company_id] = company.id
      end

      record = find_or_initialize_by(email: contact_attrs[:email])
      is_new_record = record.new_record?
      record.assign_attributes(contact_attrs.except(:email))

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
