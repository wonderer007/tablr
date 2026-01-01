class Suggestion < ApplicationRecord
  acts_as_tenant :business

  belongs_to :category
  belongs_to :review

  # Define which attributes can be searched/filtered via Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[text category_id]
  end

  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    %w[category review]
  end
end
