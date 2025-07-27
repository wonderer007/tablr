FactoryBot.define do
  factory :keyword do
    association :review
    association :category

    name do
      [
        "Karahi", "homemade donuts", "general", "dumba karahi", "food", "dhumba karahi", 
        "Machli Rosh", "wait time", "general", "prices", "lemon sole", "hospitality", 
        "general", "combo meal", "Crispy Duck Salad", "french food", "general", 
        "food", "rosh", "service", "hygiene", "ribeye", "general", "fries", "Tikka",
        "atmosphere", "general", "food", "Shinwari mutton rosh", "Chicken Tikka wrapped in Lambs Caul fat", 
        "Rosh Namkeen", "salad", "qeema karahi", "Nabin", "Shinwari mutton karahi", "staff and service", 
        "Rosh Masalah", "tiramisu", "Jomar's service", "chocolate fondant tart", "general", "champ bbq", 
        "service by Yi Lun", "price", "Masala Rosh", "BBQ Tikka", "service", "wait time", "Namkeen mutton", "seating"
      ].sample
    end
    sentiment { [:positive, :negative, :neutral].sample }
    sentiment_score { rand(0.0..1.0) }
    is_dish { [true, false].sample }
  end
end
