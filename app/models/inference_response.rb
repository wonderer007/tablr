class InferenceResponse < ApplicationRecord
  belongs_to :place

  validates :response, presence: true
end
