class Suggestion < ApplicationRecord
  belongs_to :category
  belongs_to :review
end
