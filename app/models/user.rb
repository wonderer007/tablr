class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  acts_as_tenant :place

  validates :first_name, presence: true
  validates :last_name, presence: true
  # Password not required for OAuth users
  validates :password, presence: true, unless: :oauth_user?

  belongs_to :place, optional: true

  enum :email_notification_period, [:weekly, :monthly, :weekly_and_monthly]
  enum :email_notification_time, [:morning, :afternoon]

  after_update :trigger_place_sync, if: :payment_approved_changed_to_true?

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.first_name = auth.info.first_name || auth.info.name&.split&.first || "User"
      user.last_name = auth.info.last_name || auth.info.name&.split&.last || ""
      user.avatar_url = auth.info.image
    end
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
