FactoryGirl.define do
  factory :comment do
  	content Faker::Lorem.sentence
  	new_id 0
  	volunteer_id 0
  end
end
