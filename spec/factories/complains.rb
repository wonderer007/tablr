FactoryBot.define do
  factory :complain do
    association :review
    association :category

    text do
      [
        "wait time was too long", 
        "sofas were oily and dirty", 
        "there was dirt near feet", 
        "Kabuli Pulao lacked authentic taste", 
        "Bread was Khameri Roti instead of Traditional Nan", 
        "restaurant appeared to be in need of a thorough cleaning", 
        "takes almost 2 hrs to be ready", 
        "Seekh pata kabab wasn't up to the mark", 
        "takes 1.5 hours", 
        "not recommended for families at night due to shady location"].sample
    end
  end
end
