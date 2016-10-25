FactoryGirl.define do
  factory :chatroom do
    name Faker::Name.name
    number_volunteers 0
    number_messages 0
    is_private false
  end
end
