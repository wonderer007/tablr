class DemoRequest < ApplicationRecord
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :restaurant_name, presence: true, length: { maximum: 100 }
  validates :google_map_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(['http', 'https']) }
end
