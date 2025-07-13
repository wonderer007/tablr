class Keyword < ApplicationRecord
  belongs_to :review
  belongs_to :category

  enum :sentiment, [:positive, :negative, :neutral]
end
