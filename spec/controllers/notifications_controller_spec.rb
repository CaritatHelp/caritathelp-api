require 'rails_helper'

RSpec.describe NotificationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'read' do
  	volunteer = FactoryGirl.create(:volunteer)
  	friend = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: volunteer.id, receiver_id: friend.id, notif_type: "AddFriend")

  	it "successfuly set the notification as read" do
  		log friend
  		put :read, { id: notification.id }
  		body = expect_success response
  		expect(body["response"]["read"]).to be_truthy
  	end
  end

  describe 'reply_emergency' do
  	# volunteers
  	volunteer = FactoryGirl.create(:volunteer)
  	friend = FactoryGirl.create(:volunteer)

  	# associations
  	assoc = FactoryGirl.create(:assoc)

  	# events
  	event = FactoryGirl.create(:event, assoc_id: assoc.id)
  	FactoryGirl.create(:event_volunteer, volunteer_id: friend.id, event_id: event.id, rights: "host")

  	# notifications
  	notification_add_friend = FactoryGirl.create(:notification, sender_id: volunteer.id, receiver_id: friend.id, notif_type: "AddFriend")
  	emergency = FactoryGirl.create(:notification, sender_id: friend.id, receiver_id: volunteer.id, notif_type: "Emergency", event_id: event.id, event_name: event.title, receiver_name: volunteer.fullname, receiver_thumb_path: volunteer.thumb_path)

  	it "successfuly accept an emergency" do
  		log volunteer
  		put :reply_emergency, { id: emergency.id, accept: true }
  		body = expect_success response
  		expect(friend.notifications.first.notif_type).to eq("AcceptedEmergency")
  	end

  	it "successfuly refuse an emergency" do
  		log volunteer
  		put :reply_emergency, { id: emergency.id, accept: false }
  		body = expect_success response
  		expect(friend.notifications.first.notif_type).to eq("RefusedEmergency")
  	end

  	it "fails to reply to an emergency because of rights issues" do
  		log friend
  		put :reply_emergency, { id: emergency.id, accept: true }
  		body = expect_failure response
  		expect(friend.notifications.first.notif_type).to eq("Emergency")
  	end

  	it "fails to reply to an emergency because of wrong notif type" do
  		log friend
  		put :reply_emergency, { id: notification_add_friend.id, accept: true }
  		body = expect_failure response
  	end
  end
end
