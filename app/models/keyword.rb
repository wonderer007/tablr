class Keyword < ApplicationRecord
  acts_as_tenant :place

  belongs_to :review
  belongs_to :category

  enum :sentiment, [:positive, :negative, :neutral]

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[name sentiment sentiment_score is_dish created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[review category]
  end
end
