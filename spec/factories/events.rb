FactoryGirl.define do
  factory :event do
    title Faker::Name.name
    description Faker::Lorem.sentence
    self.begin Faker::Date.between(1.day.from_now, 2.days.from_now)
    self.end Faker::Date.between(3.days.from_now, 4.days.from_now)
	place Faker::Address.city
  end
end
