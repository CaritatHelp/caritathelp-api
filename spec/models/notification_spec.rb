require 'rails_helper'

RSpec.describe Notification, type: :model do
	describe "notification creation/update/delete" do
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

		it "creates a new notification" do
			expect { FactoryGirl.create(:notification,
			sender_id: volunteer.id,
			notif_type: "JoinAssoc",
			assoc_id: assoc.id,
			receiver_id: owner.id) }.to change { Notification.count }.by(1)
		end

		it "does not create a new notification because of missing notif_type" do
			notification = Notification.new(sender_id: volunteer.id, assoc_id: assoc.id, receiver_id: owner.id)
			expect(notification.valid?).to be_falsy
			expect(notification.errors.include?(:notif_type)).to be_truthy
		end

		it "updates notification" do
			notif_type = "InviteMember"
			notification.notif_type = notif_type
			expect(notification.save).to be_truthy
			expect(notification.notif_type).to eq(notif_type)
		end

		it "deletes associations" do
			notification = FactoryGirl.create(:notification,
			sender_id: volunteer.id,
			notif_type: "JoinAssoc",
			assoc_id: assoc.id,
			receiver_id: owner.id)
			expect { notification.destroy }.to change { Notification.count }.by(-1)
		end
	end

	describe "notification's links" do
		assoc = FactoryGirl.create(:assoc)

		# members
		owner = FactoryGirl.create(:volunteer)
		admin = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")
		FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: admin.id, rights: "admin")

		# joiner
		volunteer = FactoryGirl.create(:volunteer)

		notification = FactoryGirl.create(:notification, sender_id: volunteer.id, assoc_id: assoc.id, notif_type: "JoinAssoc")
		FactoryGirl.create(:notification_volunteer, volunteer_id: owner.id, notification_id: notification.id)
		FactoryGirl.create(:notification_volunteer, volunteer_id: admin.id, notification_id: notification.id)

		it "gets the correct sender volunteer" do
			expect(notification.sender_id).to eq(volunteer.id)
		end

		it "gets the correct assoc receiver" do
			expect(notification.volunteers.first.assocs.include?(assoc)).to be_truthy
		end

		it "gets the correct volunteers receivers" do
			expect(notification.volunteers.count).to eq(2)
			expect(notification.volunteers.include?(owner)).to be_truthy
			expect(notification.volunteers.include?(admin)).to be_truthy
		end
	end


end
