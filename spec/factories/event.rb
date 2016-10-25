FactoryGirl.define do
  factory :event do
    assoc
    title Faker::Name.name
    description Faker::Lorem.sentence
    self.begin Faker::Date.backward(100)
    self.end Faker::Date.forward(100)
    place Faker::Address.city
  end
end
