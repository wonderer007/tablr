class Marketing::Email < ApplicationRecord
  self.table_name = "marketing_emails"
  belongs_to :business, optional: true
  belongs_to :marketing_contact, class_name: "Marketing::Contact", foreign_key: "marketing_contact_id"
  has_one :company, through: :marketing_contact

  # Internal application statuses
  STATUSES = %w[draft sent].freeze

  # Resend webhook event statuses
  RESEND_STATUSES = %w[
    sent
    delivered
    bounced
    failed
    opened
    clicked
    complained
    delivery_delayed
    scheduled
    received
    suppressed
  ].freeze

  validates :subject, presence: true
  validates :body, presence: true
  validates :status, presence: true
  validates :resend_status, inclusion: { in: RESEND_STATUSES }, allow_nil: true

  # Scopes for querying by resend status
  scope :delivered, -> { where(resend_status: "delivered") }
  scope :bounced, -> { where(resend_status: "bounced") }
  scope :failed, -> { where(resend_status: "failed") }
  scope :opened, -> { where(resend_status: "opened") }
  scope :clicked, -> { where(resend_status: "clicked") }
  scope :complained, -> { where(resend_status: "complained") }

  # Check if email had delivery issues
  def delivery_failed?
    %w[bounced failed complained suppressed].include?(resend_status)
  end

  # Check if email was successfully delivered
  def successfully_delivered?
    resend_status == "delivered"
  end

  # Check if recipient engaged with the email
  def engaged?
    %w[opened clicked].include?(resend_status)
  end
end
