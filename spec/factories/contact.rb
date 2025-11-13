FactoryBot.define do
  factory :marketing_contact, class: "Marketing::Contact" do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    company { Faker::Company.name }
    email_confidence { rand(0.0..1.0) }
    secondary_email { Faker::Internet.email }
    primary_email_last_verified_at { Time.zone.now }
    no_of_employees { rand(1..1000) }
    linkedin_url { Faker::Internet.url }
    company_linkedin_url { Faker::Internet.url }
    website { Faker::Internet.url }
    twitter_url { Faker::Internet.url }
    city { Faker::Address.city }
    country { Faker::Address.country }
    company_address { Faker::Address.street_address }
    company_city { Faker::Address.city }
    company_state { Faker::Address.state }
    company_country { Faker::Address.country }
    company_phone { Faker::PhoneNumber.phone_number }
  end
end
