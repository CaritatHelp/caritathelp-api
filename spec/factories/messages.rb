FactoryGirl.define do
  factory :message do
  	chatroom_id { chatroom_id }
  	volunteer_id { volunteer_id }
  	content Faker::Lorem.sentence
  end
end
