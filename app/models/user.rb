class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  acts_as_tenant :place

  validates :first_name, presence: true
  validates :last_name, presence: true

  attr_accessor :google_maps_url

  enum :email_notification_period, [:weekly, :monthly, :weekly_and_monthly]

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end
end
