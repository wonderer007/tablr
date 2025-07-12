class Review < ApplicationRecord
  belongs_to :place
  has_many :keywords
  has_many :suggestions
  has_many :complaints
end
