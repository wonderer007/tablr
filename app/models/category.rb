class Category < ApplicationRecord
  has_many :keywords

  # Define which attributes can be searched/filtered via Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[name created_at updated_at]
  end
end
