FactoryBot.define do
  factory :review do
    association :business
    review_url { Faker::Internet.url }
    external_review_id { SecureRandom.uuid }
    text { Faker::Restaurant.review  }
    stars { rand(1..5) }
    likes_count { rand(0..100) }
    food_rating { rand(1..5) }
    service_rating { rand(1..5) }
    atmosphere_rating { rand(1..5) }
    published_at { 2.months.ago }
    processed { true }
    name { Faker::Name.name }
    image_url { Faker::Internet.url }
    sentiment { ["positive", "negative", "neutral"].sample }
    data { {} }
    review_context {
      {
        "Meal type"=>"Lunch", 
        "Reservation"=>"Reservations not required", 
        "Price per person"=>"£30-40"
      }      
    }
  end
end
