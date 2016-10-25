FactoryGirl.define do
  factory :event_volunteer do
    event { FactoryGirl.build(:event) }
    volunteer { FactoryGirl.build(:volunteer) }
    rights { rights }
    level { level }
  end
end
