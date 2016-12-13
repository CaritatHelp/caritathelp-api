require 'rails_helper'

RSpec.describe NotificationVolunteer, type: :model do
	describe "link between volunteer and notification" do
		let(:assoc) { FactoryGirl.create(:assoc) }
		let(:owner) { FactoryGirl.create(:volunteer) }
		let(:link_owner) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner") }
		let(:volunteer) { FactoryGirl.create(:volunteer) }
		let(:notification) { FactoryGirl.create(:notification,
			sender_id: volunteer.id,
			notif_type: "JoinAssoc",
			assoc_id: assoc.id,
			receiver_id: owner.id) }
		let(:link) { FactoryGirl.create(:notification_volunteer, volunteer_id: owner.id, notification_id: notification.id) }

		it "get the correct volunteer and notification" do
			expect(link.volunteer.id).to eq(owner.id)
			expect(link.notification.id).to eq(notification.id)
		end
	end
end
