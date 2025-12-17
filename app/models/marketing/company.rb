class Marketing::Company < ApplicationRecord
  self.table_name = "marketing_companies"

  validates :name, presence: true

  belongs_to :place, optional: true
  has_many :marketing_contacts, class_name: "Marketing::Contact", foreign_key: "company_id", dependent: :destroy
  has_many :marketing_emails, through: :marketing_contacts

  def self.ransackable_attributes(auth_object = nil)
    %w[name linkedin_url address city state country phone google_map_url place_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    ["marketing_contacts", "place"]
  end
end
