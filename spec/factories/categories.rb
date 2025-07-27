FactoryBot.define do
  factory :category do
    association :place

    name do
      ["food", "timing", "pricing", "ambiance", "cleanliness", "service", "sentiment", "location"].sample
    end
  end
end
