class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  acts_as_tenant :place

  validates :first_name, presence: true
  validates :last_name, presence: true

  belongs_to :place

  attr_accessor :google_maps_url

  enum :email_notification_period, [:weekly, :monthly, :weekly_and_monthly]

  after_update :trigger_place_sync, if: :payment_approved_changed_to_true?

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  private

  def payment_approved_changed_to_true?
    saved_change_to_payment_approved? && payment_approved? && !payment_approved_before_last_save
  end

  def trigger_place_sync
    return unless place_id.present?
    
    Rails.logger.info "Triggering Apify::SyncPlaceJob for place_id: #{place_id} (user: #{email})"
    Apify::SyncPlaceJob.perform_later(place_id: place_id)
  end
end
