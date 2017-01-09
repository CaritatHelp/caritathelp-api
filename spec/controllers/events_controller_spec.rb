require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'index' do
  	FactoryGirl.create(:event)

  	it "get a list of the existing events" do
  		get :index
  		body = expect_success response
  		expect(body["response"].length).not_to eq(0)
  	end
  end

  describe 'create' do
  	assoc = FactoryGirl.create(:assoc)

  	# host
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")

  	# members
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: member.id, assoc_id: assoc.id, rights: "member")

  	it "creates a new event with minimum params" do
  		log owner
  		expect { post :create, { assoc_id: assoc.id, title: Faker::Name.name, description: Faker::Lorem.sentence, begin: Faker::Date.between(1.day.from_now, 2.days.from_now), end: Faker::Date.between(3.day.from_now, 4.days.from_now) } }.to change { Event.count }.by(1)
  		expect_success response
  	end

  	it "fails to create an event because of missing params" do
  		log owner
  		expect { post :create, { assoc_id: assoc.id, title: Faker::Name.name } }.to change { Event.count }.by(0)
  		expect_failure response
  	end

  	it "fails to create an event because of rights issues" do
  		log member
  		expect { post :create, { assoc_id: assoc.id, title: Faker::Name.name, description: Faker::Lorem.sentence, begin: Faker::Date.between(1.day.from_now, 2.days.from_now), end: Faker::Date.between(3.day.from_now, 4.days.from_now) } }.to change { Event.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'show' do
  	event = FactoryGirl.create(:event)
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event.id, rights: "host")

  	it "shows an event's details" do
  		get :show, { id: event.id }
  		body = expect_success response
  		expect(body["response"]["id"]).to eq(event.id)
  		expect(body["response"]["rights"]).to eq(nil)
  	end

  	it "shows an event's details with logged in volunteer's rights" do
  		log host
  		get :show, { id: event.id }
  		body = expect_success response
  		expect(body["response"]["id"]).to eq(event.id)
  		expect(body["response"]["rights"]).to eq("host")
  	end
  end

  describe 'guests' do
  	event = FactoryGirl.create(:event)
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event.id, rights: "host")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: member.id, event_id: event.id, rights: "member")
  	volunteer = FactoryGirl.create(:volunteer)

  	it "gets a list of all event's guests" do
  		log host
  		get :guests, { id: event.id }
  		body = expect_success response
  		expect { body["response"].include?(host) and body["response"].include?(member) and body["response"].exclude?(volunteer) and body["response"].length == 2 }
  	end
  end

  describe 'update' do
  	event = FactoryGirl.create(:event)
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event.id, rights: "host")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: member.id, event_id: event.id, rights: "member")

  	it "successfuly update event's fields" do
  		log host
  		new_title = Faker::Name.name
  		put :update, { id: event.id, title: new_title }
  		body = expect_success response
  		expect(body["response"]["title"]).to eq(new_title)
  	end

  	it "fails to update event's fields because of rights issues" do
  		log member
  		old_title = event.title
  		put :update, { id: event.id, title: Faker::Name.name }
  		body = expect_failure response
  		expect(event.title).to eq(old_title)
  	end
  end

  describe 'delete' do
  	event = FactoryGirl.create(:event)
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event.id, rights: "host")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: member.id, event_id: event.id, rights: "member")

  	it "successfuly delete an event" do
  		log host
  		expect { delete :delete, { id: event.id } }.to change { Event.count }.by(-1)
  		expect_success response
  	end

  	it "fails to delete an event because of rights issues" do
  		log member
  		expect { delete :delete, { id: event.id } }.to change { Event.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'owned' do
  	event1 = FactoryGirl.create(:event)
  	event2 = FactoryGirl.create(:event)
  	event3 = FactoryGirl.create(:event)
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event1.id, rights: "host")
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event2.id, rights: "host")
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event3.id, rights: "admin")

  	it "gets the 2 owned event" do
  		log host
  		get :owned
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(event1, event2) }
  	end
  end

  describe 'invited' do
  	event1 = FactoryGirl.create(:event)
  	event2 = FactoryGirl.create(:event)
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event1.id, rights: "host")
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event2.id, rights: "host")
  	volunteer = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: host.id, receiver_id: volunteer.id, event_id: event1.id, notif_type: "InviteGuest")
  	FactoryGirl.create(:notification, sender_id: host.id, receiver_id: volunteer.id, event_id: event2.id, notif_type: "InviteGuest")

  	it "successfuly get the list of all the events the volunteer is invited to" do
  		log volunteer
  		get :invited
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(event1) and body["response"].include?(event2) }
  	end
  end

  describe 'joining' do
  	event1 = FactoryGirl.create(:event)
  	event2 = FactoryGirl.create(:event)
  	volunteer = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: volunteer.id, event_id: event1.id, notif_type: "JoinEvent")
  	FactoryGirl.create(:notification, sender_id: volunteer.id, event_id: event2.id, notif_type: "JoinEvent")

  	it "successfuly get the list of all the events the volunteer is joining" do
  		log volunteer
  		get :joining
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(event1) and body["response"].include?(event2) }
  	end
  end

  describe 'pictures' do
  	event = FactoryGirl.create(:event)

  	it "gets a list of all the event's pictures" do
  		get :pictures, { id: event.id }
  		body = expect_success response
  	end
  end

  describe 'main_picture' do
  	event = FactoryGirl.create(:event)

  	it "gets a list of the event main picture" do
  		get :pictures, { id: event.id }
  		expect_success response
  	end
  end

  describe 'news' do
  	event = FactoryGirl.create(:event)

  	# members
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, volunteer_id: host.id, event_id: event.id, rights: "host")

  	# non members
  	volunteer = FactoryGirl.create(:volunteer)

  	# public news
  	FactoryGirl.create(:new, group_id: event.id, group_type: "Event", group_name: event.title, group_thumb_path: event.thumb_path, as_group: true, volunteer_name: host.fullname, volunteer_thumb_path: host.thumb_path, volunteer_id: host.id)
  	FactoryGirl.create(:new, group_id: event.id, group_type: "Event", group_name: event.title, group_thumb_path: event.thumb_path, as_group: true, volunteer_name: host.fullname, volunteer_thumb_path: host.thumb_path, volunteer_id: host.id)

  	# private news
  	FactoryGirl.create(:new, group_id: event.id, group_type: "Event", group_name: event.title, group_thumb_path: event.thumb_path, as_group: true, volunteer_name: host.fullname, volunteer_thumb_path: host.thumb_path, volunteer_id: host.id, private: true)

  	it "returns public & private news" do
  		log host
  		get :news, { id: event.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(3)
  	end

  	it "returns only the public news" do
  		log volunteer
  		get :news, { id: event.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end
  end

  describe 'raise_emergency' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, latitude: 48.8587741, longitude: 2.2074741)

  	# event host & assoc owner
  	kremlin = FactoryGirl.create(:volunteer, latitude: 48.8066706, longitude: 2.3654136000000108, allowgps: true)
  	FactoryGirl.create(:av_link, volunteer_id: kremlin.id, assoc_id: assoc.id, rights: "owner")
  	FactoryGirl.create(:event_volunteer, volunteer_id: kremlin.id, event_id: event.id, rights: "host")

  	# assoc members
  	paris = FactoryGirl.create(:volunteer, latitude: 48.8587741, longitude: 2.2074741, allowgps: true)
  	sf = FactoryGirl.create(:volunteer, latitude: 37.7749295, longitude: -122.41941550000001, allowgps: true)
  	versailles = FactoryGirl.create(:volunteer, latitude: 48.801408, longitude: 2.1301220000000285, allowgps: true)
  	marseille = FactoryGirl.create(:volunteer, latitude: 43.296482, longitude: 5.369779999999992, allowgps: true)
  	FactoryGirl.create(:av_link, volunteer_id: paris.id, assoc_id: assoc.id, rights: "member")
  	FactoryGirl.create(:av_link, volunteer_id: sf.id, assoc_id: assoc.id, rights: "member")
  	FactoryGirl.create(:av_link, volunteer_id: versailles.id, assoc_id: assoc.id, rights: "member")
  	FactoryGirl.create(:av_link, volunteer_id: marseille.id, assoc_id: assoc.id, rights: "member")

  	it "sends notifications and returns a list of the members not in the event located in paris, versailles & kremlin" do
  		log kremlin
  		expect { post :raise_emergency, { id: event.id } }.to change { Notification.count }.by(2)
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(paris, versailles) }
  	end

  	it "sends notifications and returns a list of the members not in the event located in paris, versailles, kremlin & marseille" do
  		log kremlin
  		expect { post :raise_emergency, { id: event.id, zone: 1000 } }.to change { Notification.count }.by(3)
  		body = expect_success response
  		expect { body["response"].length == 3 and body["response"].include?(paris, versailles, marseille) }
  	end
  end
end
