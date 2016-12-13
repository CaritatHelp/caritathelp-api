FactoryGirl.define do
  factory :event_volunteer do
    event_id { event_id }
    volunteer_id { volunteer_id }
    rights { rights }
		level { level }
  end
end
