FactoryBot.define do
  factory :suggestion do
    association :review
    association :category

    text do
      [
        "add more vegetarian options", 
        "add more non-alcoholic drinks", 
        "add more desserts", 
        "add more vegan options", 
        "add more gluten-free options", 
        "add more halal options", 
        "add more kosher options", 
        "add more halal options", 
        "add more kosher options"].sample
    end
  end
end
