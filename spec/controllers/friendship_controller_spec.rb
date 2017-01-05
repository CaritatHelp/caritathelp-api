require 'rails_helper'

RSpec.describe FriendshipController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'add' do
  	volunteer = FactoryGirl.create(:volunteer)
  	not_friend = FactoryGirl.create(:volunteer)
  	friend = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend.id)
  	FactoryGirl.create(:v_friend, volunteer_id: friend.id, friend_volunteer_id: volunteer.id)

  	it "successfuly send a friend request" do
  		log volunteer
  		expect { post :add, { volunteer_id: not_friend.id} }.to change { Notification.count }.by(1)
  		expect_success response
  	end

  	it "fails to send a friend request to a friend" do
  		log volunteer
  		expect { post :add, { volunteer_id: friend.id} }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "fails to send a friend request to yourself" do
  		log volunteer
  		expect { post :add, { volunteer_id: volunteer.id} }.to change { Notification.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'reply' do
  	volunteer = FactoryGirl.create(:volunteer)
  	not_friend = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: volunteer.id, receiver_id: not_friend.id, notif_type: "AddFriend")

  	it "successfuly accept a friend" do
  		log not_friend
  		expect { post :reply, { notif_id: notification.id, acceptance: "true"} }.to change { Notification.count }.by(-1).and change { VFriend.count }.by(2)
  		expect_success response
  		expect(volunteer.volunteers.include?(not_friend)).to be_truthy
  	end

  	it "fails to accept friend because of rights issues" do
  		log volunteer
  		expect { post :reply, { notif_id: notification.id, acceptance: "true"} }.to change { Notification.count }.by(0).and change { VFriend.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'remove' do
  	volunteer = FactoryGirl.create(:volunteer)
  	not_friend = FactoryGirl.create(:volunteer)
  	friend = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend.id)
  	FactoryGirl.create(:v_friend, volunteer_id: friend.id, friend_volunteer_id: volunteer.id)

  	it "successfuly remove friendship" do
  		log volunteer
  		expect { delete :remove, { volunteer_id: friend.id } }.to change{ VFriend.count }.by(-2)
  		expect_success response
  		expect(volunteer.volunteers.exclude?(friend)).to be_truthy
  	end

  	it "fails to remove friendship because no existing friendship" do
  		log volunteer
  		expect { delete :remove, { volunteer_id: not_friend.id } }.to change{ VFriend.count }.by(0)
  		expect_failure response
  		expect(volunteer.volunteers.exclude?(not_friend)).to be_truthy
  	end
  end

  describe 'cancel_request' do
  	volunteer = FactoryGirl.create(:volunteer)
  	not_friend = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: volunteer.id, receiver_id: not_friend.id, notif_type: "AddFriend")

  	it "successfuly cancel a friend request" do
  		log volunteer
  		expect { delete :cancel_request, { notif_id: notification.id } }.to change { Notification.count }.by(-1)
  		expect_success response
  	end

  	it "fails to cancel a friend request because of rights issues" do
  		log not_friend
  		expect { delete :cancel_request, { notif_id: notification.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "fails to cancel an unexisting friend request" do
  		log volunteer
  		expect { delete :cancel_request, { notif_id: notification.id + Faker::Number.number(5).to_i } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'received_invitations' do
  	volunteer = FactoryGirl.create(:volunteer)
  	not_friend1 = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: not_friend1.id, receiver_id: volunteer.id, notif_type: "AddFriend")
  	not_friend2 = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: not_friend2.id, receiver_id: volunteer.id, notif_type: "AddFriend")

  	it "successfuly get a list of received invitations" do
  		log volunteer
  		get :received_invitations
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end
  end
end
