FactoryGirl.define do
  factory :volunteer do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    email { Faker::Internet.email }
    password "password1234"
  end
end
