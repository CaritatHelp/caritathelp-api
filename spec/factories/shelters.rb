FactoryGirl.define do
  factory :shelter do
    name Faker::Name.name
    address Faker::Address.street_address
    zipcode Faker::Address.zip
    city Faker::Address.city
    total_places Faker::Number.number(3)
		free_places Faker::Number.number(2)
  end
end
