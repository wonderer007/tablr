class InferenceResponse < ApplicationRecord
  belongs_to :business

  validates :response, presence: true
end
