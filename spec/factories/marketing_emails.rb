FactoryBot.define do
  factory :marketing_email do
    marketing_contact_id { 1 }
    place_id { 1 }
    subject { "Test marketing email subject" }
    body { "<p>Sample marketing email body.</p>" }
    status { "draft" }
    ai_generated_intro { "AI rephrased opening line one.\nAI rephrased opening line two." }
  end
end
