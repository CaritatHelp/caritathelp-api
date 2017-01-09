require 'rails_helper'

RSpec.describe VolunteersController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe "index" do
  	volunteer = FactoryGirl.create(:volunteer)

  	it "get a list of existing volunteers" do
  		log volunteer
  		get :index
  		body = expect_success response
  		expect(body["response"].length).not_to eq(0)
  	end
  end

  describe "show" do
  	volunteer = FactoryGirl.create(:volunteer)
  	friend = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: volunteer.id, receiver_id: friend.id, notif_type: "AddFriend")

  	it "shows a volunteer's details with a sent friend request" do
  		log volunteer
  		get :show, { id: friend.id }
  		body = expect_success response
  		expect(body["response"]["id"]).to eq(friend.id)
  		expect(body["response"]["friendship"]).to eq("invitation sent")
  	end

  	it "shows a volunteer's details with a received friend request" do
  		log friend
  		get :show, { id: volunteer.id }
  		body = expect_success response
  		expect(body["response"]["id"]).to eq(volunteer.id)
  		expect(body["response"]["friendship"]).to eq("invitation received")
  	end
  end

  describe "notifications" do
  	volunteer = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: 0, receiver_id: volunteer.id, notif_type: "AddFriend")
  	FactoryGirl.create(:notification, sender_id: 0, receiver_id: volunteer.id, notif_type: "AddFriend")
  	FactoryGirl.create(:notification, sender_id: 0, receiver_id: volunteer.id, notif_type: "AddFriend")

  	it "gets a list of all volunteer's notifications" do
  		log volunteer
  		get :notifications
  		body = expect_success response
  		expect(body["response"].length).to eq(3)
  	end
  end

  describe "friends" do
  	volunteer = FactoryGirl.create(:volunteer)
  	friend1 = FactoryGirl.create(:volunteer)
  	friend2 = FactoryGirl.create(:volunteer)
  	friend3 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend1.id)
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend2.id)
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend3.id)

  	it "gets a list of all volunteer's friends" do
  		log volunteer
  		get :friends, { id: volunteer.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(3)
  	end
  end

  describe "associations" do
  	volunteer = FactoryGirl.create(:volunteer)
  	assoc1 = FactoryGirl.create(:assoc)
  	assoc2 = FactoryGirl.create(:assoc)
  	FactoryGirl.create(:av_link, volunteer_id: volunteer.id, assoc_id: assoc1.id, rights: "member")
  	FactoryGirl.create(:av_link, volunteer_id: volunteer.id, assoc_id: assoc2.id, rights: "member")

  	it "gets a list of all volunteer's associations" do
  		log volunteer
  		get :associations, { id: volunteer.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end
  end

  describe "events" do
  	volunteer = FactoryGirl.create(:volunteer)
  	event1 = FactoryGirl.create(:event)
  	event2 = FactoryGirl.create(:event)
  	event3 = FactoryGirl.create(:event)
  	FactoryGirl.create(:event_volunteer, volunteer_id: volunteer.id, event_id: event1.id, rights: "member")
  	FactoryGirl.create(:event_volunteer, volunteer_id: volunteer.id, event_id: event2.id, rights: "member")
  	FactoryGirl.create(:event_volunteer, volunteer_id: volunteer.id, event_id: event3.id, rights: "member")

  	it "gets a list of all volunteer's events" do
  		log volunteer
  		get :events, { id: volunteer.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(3)
  	end
  end

  describe "friend_requests" do
  	volunteer = FactoryGirl.create(:volunteer)
  	not_friend1 = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: not_friend1.id, receiver_id: volunteer.id, notif_type: "AddFriend")
  	not_friend2 = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: not_friend2.id, receiver_id: volunteer.id, notif_type: "AddFriend")

  	it "successfuly get a list of pending friends invitations" do
  		log volunteer
  		get :friend_requests
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end
  end

  describe 'pictures' do
  	volunteer = FactoryGirl.create(:volunteer)

  	it "gets a list of all the volunteer's pictures" do
  		log volunteer
  		get :pictures, { id: volunteer.id }
  		body = expect_success response
  	end
  end

  describe 'main_picture' do
  	volunteer = FactoryGirl.create(:volunteer)

  	it "gets a list of the volunteer main picture" do
  		log volunteer
  		get :pictures, { id: volunteer.id }
  		expect_success response
  	end
  end

  describe "news" do
  	volunteer = FactoryGirl.create(:volunteer)
  	not_friend = FactoryGirl.create(:volunteer)
  	friend = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend.id)
  	FactoryGirl.create(:v_friend, volunteer_id: friend.id, friend_volunteer_id: volunteer.id)

  	# public news
  	FactoryGirl.create(:news, group_id: volunteer.id, group_type: "Volunteer", group_name: volunteer.fullname, group_thumb_path: volunteer.thumb_path, as_group: true, volunteer_name: volunteer.fullname, volunteer_thumb_path: volunteer.thumb_path, volunteer_id: volunteer.id)
  	FactoryGirl.create(:news, group_id: volunteer.id, group_type: "Volunteer", group_name: volunteer.fullname, group_thumb_path: volunteer.thumb_path, as_group: true, volunteer_name: volunteer.fullname, volunteer_thumb_path: volunteer.thumb_path, volunteer_id: volunteer.id)

  	# private news
  	FactoryGirl.create(:news, group_id: volunteer.id, group_type: "Volunteer", group_name: volunteer.fullname, group_thumb_path: volunteer.thumb_path, as_group: true, volunteer_name: volunteer.fullname, volunteer_thumb_path: volunteer.thumb_path, volunteer_id: volunteer.id, private: true)

  	it "returns public & private news" do
  		log friend
  		get :news, { id: volunteer.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(3)
  	end

  	it "returns only the public news" do
  		log not_friend
  		get :news, { id: volunteer.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end
  end
end
