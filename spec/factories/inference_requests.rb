FactoryBot.define do
  factory :inference_request do
    association :business
    response { {} }
    input_token_count { nil }
    output_token_count { nil }
  end
end

