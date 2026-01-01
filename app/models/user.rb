class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  acts_as_tenant :business

  validates :first_name, presence: true
  validates :last_name, presence: true
  # Password not required for OAuth users
  validates :password, presence: true, unless: :oauth_user?

  belongs_to :business, optional: true

  enum :email_notification_period, [:weekly, :monthly, :weekly_and_monthly]
  enum :email_notification_time, [:morning, :afternoon]

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  def needs_onboarding?
    business.nil? || business.needs_onboarding?
  end

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user.present?

    # Create new user with a business for onboarding
    user = new(
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email,
      password: Devise.friendly_token[0, 20],
      first_name: auth.info.first_name || auth.info.name&.split&.first || "User",
      last_name: auth.info.last_name || "",
      avatar_url: auth.info.image
    )

    # Create business first, then associate
    ActiveRecord::Base.transaction do
      business = Business.create!(business_type: :google_place, status: :created)
      user.business = business
      user.save!
    end

    user
  end

end
