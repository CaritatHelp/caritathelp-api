require 'rails_helper'

RSpec.describe VFriend, type: :model do
	describe "link between volunteers" do
		volunteer = FactoryGirl.create(:volunteer)
		friend = FactoryGirl.create(:volunteer)
    link_friend = FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend.id)

		it "get the correct volunteer and event" do
			expect(link_friend.volunteer_id).to eq(volunteer.id)
			expect(link_friend.friend_volunteer_id).to eq(friend.id)
		end
	end
end
