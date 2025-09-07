FactoryBot.define do
  factory :outreach_email, class: 'Outreach::Email' do
    first_name { "MyString" }
    last_name { "MyString" }
    email { "MyString" }
    company { "MyString" }
  end
end
