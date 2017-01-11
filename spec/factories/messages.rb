FactoryGirl.define do
  factory :message do
  	chatroom_id 0
  	volunteer_id 0
  	content Faker::Lorem.sentence
  end
end
