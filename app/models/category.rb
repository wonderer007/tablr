class Category < ApplicationRecord
  acts_as_tenant :place

  has_many :keywords
  has_many :suggestions
  has_many :complains

  # Define which attributes can be searched/filtered via Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[name created_at updated_at]
  end
end
