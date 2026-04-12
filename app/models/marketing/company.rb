class Marketing::Company < ApplicationRecord
  self.table_name = "marketing_companies"

  validates :name, presence: true

  belongs_to :business, optional: true
  has_many :marketing_contacts, class_name: "Marketing::Contact", foreign_key: "company_id", dependent: :destroy
  has_many :marketing_emails, through: :marketing_contacts

  scope :ready_for_outreach, -> {
    where(google_map_url: [nil, ""])
      .joins(:marketing_contacts)
      .where(marketing_contacts: { email_status: nil })
      .where.not(
        id: Marketing::Company
              .joins(marketing_contacts: :marketing_emails)
              .select(:id)
      ).distinct
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[name linkedin_url address city state country phone google_map_url business_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    ["marketing_contacts", "business"]
  end

  def self.ransackable_scopes(auth_object = nil)
    %i[ready_for_outreach]
  end
end
