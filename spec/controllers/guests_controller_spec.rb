require 'rails_helper'

RSpec.describe GuestsController, type: :controller do
	include Devise::Test::ControllerHelpers

  describe 'kick' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id)

  	# members
  	admin = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: admin.id, rights: "admin")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member.id, rights: "member")
  	member_to_kick = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member_to_kick.id, rights: "member")

    it "fails to kick a member because of rights issue" do
    	log member
    	delete :kick, { event_id: event.id, volunteer_id: member_to_kick.id }

    	expect_failure response
    	expect(event.volunteers.include?(member_to_kick)).to be_truthy
    end

    it "successfuly kicks a volunteer" do
    	log admin
    	delete :kick, { event_id: event.id, volunteer_id: member_to_kick.id }

    	expect_success response
    	expect(event.volunteers.include?(member_to_kick)).to be_falsy
    end
  end

  describe 'upgrade' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id)

  	# members
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")
  	admin = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: admin.id, rights: "admin")
  	member1 = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member1.id, rights: "member")
  	member2 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member2.id, rights: "member")

  	it "fails to upgrade a member because of rights issue" do
  		log member1
  		put :upgrade, { event_id: event.id, volunteer_id: member2.id, rights: "admin" }

  		expect_failure response
  		link = member2.event_volunteers.find_by(event_id: event.id)
  		expect(link.rights).to eq("member")
  	end

  	it "fails to downgrade an admin because of rights issue" do
  		log member1
  		put :upgrade, { event_id: event.id, volunteer_id: admin.id, rights: "member" }

  		expect_failure response
  		link = admin.event_volunteers.find_by(event_id: event.id)
  		expect(link.rights).to eq("admin")
  	end

  	it "successfuly upgrades a volunteer" do
  		log admin
  		put :upgrade, { event_id: event.id, volunteer_id: member1.id, rights: "admin" }

  		expect_success response
  		link = member1.event_volunteers.find_by(event_id: event.id)
  		expect(link.rights).to eq("admin")
  	end

  	it "successfuly downgrades an admin" do
  		log host
  		put :upgrade, { event_id: event.id, volunteer_id: admin.id, rights: "member" }

  		expect_success response
  		link = admin.event_volunteers.find_by(event_id: event.id)
  		expect(link.rights).to eq("member")
  	end
  end

  describe 'join' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, private: true)

  	# members
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")
  	admin = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: admin.id, rights: "admin")
  	member = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member.id, rights: "member")

		# joiner
  	volunteer = FactoryGirl.create(:volunteer)

  	it "successfuly ask to join the event" do
  		log volunteer
  		post :join, { event_id: event.id }

  		expect_success response
  		expect(Notification.last.volunteers.include?(host)).to be_truthy
  		expect(Notification.last.volunteers.include?(admin)).to be_truthy
  		expect(Notification.last.volunteers.include?(member)).to be_falsy
  		expect(Notification.last.sender_id).to eq(volunteer.id)
  	end

  	it "fails because already member" do
  		log member
  		post :join, { event_id: event.id }
  		expect_failure response
  	end
  end

  describe 'reply_guest' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, private: true)

  	# members
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")
  	member = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member.id, rights: "member")

		# joiner
  	volunteer = FactoryGirl.create(:volunteer)
		notification = FactoryGirl.create(:notification, sender_id: volunteer.id, notif_type: "JoinEvent", event_id: event.id)

		it "fails to reply member because of rights issue" do
			log member
			post :reply_guest, { notif_id: notification.id, acceptance: true }
			expect_failure response
		end

		it "successfuly accepted member" do
			log host
			post :reply_guest, { notif_id: notification.id, acceptance: true }

			expect_success response
			expect(event.volunteers.include?(volunteer)).to be_truthy
		end

		it "successfuly refused volunteer" do
			log host
			post :reply_guest, { notif_id: notification.id, acceptance: false }

			expect_success response
			expect(event.volunteers.include?(volunteer)).to be_falsy
		end
  end

  describe 'invite' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id)

  	# members
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")
  	member = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member.id, rights: "member")

		# non members
  	volunteer = FactoryGirl.create(:volunteer)

  	it "fails to invite because of rights issue" do
  		log member
  		expect { post :invite, { event_id: event.id, volunteer_id: volunteer.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "fails to invite because already member" do
  		log host
  		expect { post :invite, { event_id: event.id, volunteer_id: member.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "successfuly invites a volunteer to join the event" do
  		log host
  		expect { post :invite, { event_id: event.id, volunteer_id: volunteer.id } }.to change { Notification.count }.by(1)
  		expect_success response
  	end
  end

  describe 'reply_invite' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, private: true)

  	# members
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")

		# non members
  	volunteer = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: host.id, notif_type: "InviteGuest", event_id: event.id, receiver_id: volunteer.id, assoc_id: 0)

		it "fails to reply invite because of rights issue" do
			log host
			post :reply_invite, { notif_id: notification.id, acceptance: 'true' }
			expect_failure response
		end

		it "successfuly accepted invitation" do
			log volunteer
			post :reply_invite, { notif_id: notification.id, acceptance: 'true' }

			expect_success response
			expect(event.volunteers.include?(volunteer)).to be_truthy
		end

		it "successfuly refused invitation" do
			log volunteer
			post :reply_invite, { notif_id: notification.id, acceptance: 'false' }

			expect_success response
			expect(event.volunteers.include?(volunteer)).to be_falsy
		end
  end

  describe 'leave_event' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: 1)

  	# member
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: member.id, rights: "member")

  	# non member
  	volunteer = FactoryGirl.create(:volunteer)

  	it "fails to leave event because not member" do
  		log member
  		delete :leave_event, { event_id: event.id }

  		expect_success response
  		expect(event.volunteers.include?(member)).to be_falsy
  	end

  	it "successfuly leave the event" do
  		log volunteer
  		delete :leave_event, { event_id: event.id }

  		expect_failure response
  		expect(event.volunteers.include?(volunteer)).to be_falsy
  	end
  end

  describe 'invited' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, private: true)

  	# host
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")

  	# invited volunteers
  	guest1 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: host.id, receiver_id: guest1.id, event_id: event.id, notif_type: "InviteGuest", assoc_id: 0)
  	guest2 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: host.id, receiver_id: guest2.id, event_id: event.id, notif_type: "InviteGuest", assoc_id: 0)

  	it "successfuly get the list of all invited users" do
  		log host
  		get :invited, { event_id: event.id }

  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end

  	it "fails to get the list of all invited users because of rights issues" do
  		log guest1
  		get :invited, { event_id: event.id }

  		expect_failure response
  	end
  end

  describe 'uninvite' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, private: true)

  	# host
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")

  	# invited volunteer
  	guest = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: host.id, receiver_id: guest.id, event_id: event.id, notif_type: "InviteGuest")

  	# non invited volunteer
  	volunteer = FactoryGirl.create(:volunteer)

  	it "successfuly uninvite volunteer" do
  		log host
  		expect { delete :uninvite, { event_id: event.id, volunteer_id: guest.id } }.to change { Notification.count }.by(-1)
  		expect_success response
  	end

  	it "fails to uninvite volunteer because of rights issues" do
  		log volunteer
  		expect { delete :uninvite, { event_id: event.id, volunteer_id: guest.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "fails to uninvite volunteer because he was not invited" do
  		log host
  		expect { delete :uninvite, { event_id: event.id, volunteer_id: volunteer.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'unjoin' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, private: true)

  	# joining volunteer
  	joiner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: joiner.id, event_id: event.id, notif_type: "JoinEvent")

  	# non joining volunteer
  	volunteer = FactoryGirl.create(:volunteer)

  	it "successfuly cancel a join request" do
  		log joiner
  		expect { delete :unjoin, { event_id: event.id }}.to change { Notification.count }.by(-1)
  		expect_success response
  	end

  	it "fails to cancel a non existing join request" do
  		log volunteer
  		expect { delete :unjoin, { event_id: event.id }}.to change { Notification.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'waiting' do
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id, private: true)

  	# host
  	host = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host")

  	# joining volunteer
  	joiner1 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: joiner1.id, event_id: event.id, notif_type: "JoinEvent")
  	joiner2 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: joiner2.id, event_id: event.id, notif_type: "JoinEvent")

  	it "successfuly get the list of joining volunteers" do
  		log host
  		get :waiting, { event_id: event.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end

  	it "fails to get the list of joining volunteers because of rights issues" do
  		log joiner1
  		get :waiting, { event_id: event.id }
			expect_failure response
  	end
  end
end
