FactoryBot.define do
  factory :category do
    association :business

    name do
      ["food", "timing", "pricing", "ambiance", "cleanliness", "service", "sentiment", "location"].sample
    end
  end
end
