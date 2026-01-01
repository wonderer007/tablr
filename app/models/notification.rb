class Notification < ApplicationRecord
  acts_as_tenant :business

  belongs_to :business

  scope :recent, ->(limit = 8) { where(read: false).order(created_at: :desc).limit(limit) }
  scope :unread, -> { where(read: false) }
end
