class Marketing::Email < ApplicationRecord
  self.table_name = "marketing_emails"
  belongs_to :business, optional: true
  belongs_to :marketing_contact, class_name: "Marketing::Contact", foreign_key: "marketing_contact_id"
  has_one :company, through: :marketing_contact

  validates :subject, presence: true
  validates :body, presence: true
  validates :status, presence: true
end
