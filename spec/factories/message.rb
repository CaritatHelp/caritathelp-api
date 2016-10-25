FactoryGirl.define do
  factory :message do
    content Faker::Lorem.sentence
    chatroom { chatroom }
    volunteer { volunteer }
  end
end
