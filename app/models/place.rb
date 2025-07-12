class Place < ApplicationRecord
  ACTOR_ID = '2Mdma1N6Fd0y3QEjR'

  validates :url, presence: true, uniqueness: true

  has_many :reviews

  enum :status, [:created, :syncing_place, :synced_place, :syncing_reviews, :synced_reviews, :failed]
end
