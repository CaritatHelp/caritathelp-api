require 'rails_helper'

RSpec.describe EventVolunteer, type: :model do
	describe "link between volunteer and event" do
		assoc = FactoryGirl.create(:assoc)
		event = FactoryGirl.create(:event, assoc_id: assoc.id)
		guest = FactoryGirl.create(:volunteer)
    	link_guest = FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: guest.id, rights: "member", level: 5)

		it "upgrade volunteer" do
			link_guest.rights = "admin"
			link_guest.save
			expect(link_guest.level).to eq(8)
		end

		it "downgrade volunteer" do
			link_guest.rights = "member"
			link_guest.save
			expect(link_guest.level).to eq(5)
		end

		it "get the correct volunteer and event" do
			expect(link_guest.event.id).to eq(event.id)
			expect(link_guest.volunteer.id).to eq(guest.id)
		end
	end
end
