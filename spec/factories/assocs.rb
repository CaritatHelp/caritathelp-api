FactoryGirl.define do
  factory :assoc do
  	name Faker::Name.name
  	description Faker::Lorem.sentence
    birthday Faker::Date.backward(100)
    city Faker::Address.city
    latitude Faker::Address.latitude
		longitude Faker::Address.longitude
  end
end
