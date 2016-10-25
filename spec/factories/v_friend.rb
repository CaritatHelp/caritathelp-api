FactoryGirl.define do
  factory :v_friend do
    volunteer_id { FactoryGirl.build(:volunteer).id }
    friend_volunteer_id { FactoryGirl.build(:volunteer).id }
  end
end
