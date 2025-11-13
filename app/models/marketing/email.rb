class Marketing::Email < ApplicationRecord
  self.table_name = "marketing_emails"
  belongs_to :place
  belongs_to :marketing_contact, class_name: "Marketing::Contact"

  validates :subject, presence: true
  validates :body, presence: true
  validates :sent_at, presence: true
  validates :status, presence: true
end
