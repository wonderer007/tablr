FactoryBot.define do
  factory :business do
    name { Faker::Company.name }
    status { :synced_reviews }
    review_synced_at { Time.zone.now }
    place_synced_at { Time.zone.now }
    rating { rand(1..5) }
    url { Faker::Internet.url }
    data { {} }
    business_type { 'google_place' }
  end
end

