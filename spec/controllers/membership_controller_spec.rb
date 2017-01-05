require 'rails_helper'

RSpec.describe MembershipController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'kick' do
  	assoc = FactoryGirl.create(:assoc)

  	# members
  	admin = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: admin.id, rights: "admin")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id, rights: "member")
  	member_to_kick = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member_to_kick.id, rights: "member")

    it "fails to kick a member because of rights issue" do
    	log member
    	delete :kick, { assoc_id: assoc.id, volunteer_id: member_to_kick.id }

    	expect_failure response
    	expect(assoc.volunteers.include?(member_to_kick)).to be_truthy
    end

    it "successfuly kicks a volunteer" do
    	log admin
    	delete :kick, { assoc_id: assoc.id, volunteer_id: member_to_kick.id }

    	expect_success response
    	expect(assoc.volunteers.include?(member_to_kick)).to be_falsy
    end
  end

  describe 'upgrade' do
  	assoc = FactoryGirl.create(:assoc)

  	# members
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")
  	admin = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: admin.id, rights: "admin")
  	member1 = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member1.id, rights: "member")
  	member2 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member2.id, rights: "member")

  	it "fails to upgrade a member because of rights issue" do
  		log member1
  		put :upgrade, { assoc_id: assoc.id, volunteer_id: member2.id, rights: "admin" }

  		expect_failure response
  		link = member2.av_links.find_by(assoc_id: assoc.id)
  		expect(link.rights).to eq("member")
  	end

  	it "fails to downgrade an admin because of rights issue" do
  		log member1
  		put :upgrade, { assoc_id: assoc.id, volunteer_id: admin.id, rights: "member" }

  		expect_failure response
  		link = admin.av_links.find_by(assoc_id: assoc.id)
  		expect(link.rights).to eq("admin")
  	end

  	it "successfuly upgrades a volunteer" do
  		log admin
  		put :upgrade, { assoc_id: assoc.id, volunteer_id: member1.id, rights: "admin" }

  		expect_success response
  		link = member1.av_links.find_by(assoc_id: assoc.id)
  		expect(link.rights).to eq("admin")
  	end

  	it "successfuly downgrades an admin" do
  		log owner
  		put :upgrade, { assoc_id: assoc.id, volunteer_id: admin.id, rights: "member" }

  		expect_success response
  		link = admin.av_links.find_by(assoc_id: assoc.id)
  		expect(link.rights).to eq("member")
  	end
  end

  describe 'join_assoc' do
  	assoc = FactoryGirl.create(:assoc)

  	# members
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")
  	admin = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: admin.id, rights: "admin")
  	member = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id, rights: "member")

		# joiner
  	volunteer = FactoryGirl.create(:volunteer)

  	it "successfuly ask to join the association" do
  		log volunteer
  		post :join_assoc, { assoc_id: assoc.id }

  		expect_success response
  		expect(Notification.last.volunteers.include?(owner)).to be_truthy
  		expect(Notification.last.volunteers.include?(admin)).to be_truthy
  		expect(Notification.last.volunteers.include?(member)).to be_falsy
  		expect(Notification.last.sender_id).to eq(volunteer.id)
  	end

  	it "fails because already member" do
  		log member
  		post :join_assoc, { assoc_id: assoc.id }
  		expect_failure response
  	end
  end

  describe 'reply_member' do
  	assoc = FactoryGirl.create(:assoc)

  	# members
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")
  	member = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id, rights: "member")

		# joiner
  	volunteer = FactoryGirl.create(:volunteer)
		notification = FactoryGirl.create(:notification, sender_id: volunteer.id, notif_type: "JoinAssoc", assoc_id: assoc.id)

		it "fails to reply member because of rights issue" do
			log member
			post :reply_member, { notif_id: notification.id, acceptance: 'true' }
			expect_failure response
		end

		it "successfuly accepted member" do
			log owner
			post :reply_member, { notif_id: notification.id, acceptance: 'true' }

			expect_success response
			expect(assoc.volunteers.include?(volunteer)).to be_truthy
		end

		it "successfuly refused volunteer" do
			log owner
			post :reply_member, { notif_id: notification.id, acceptance: 'false' }

			expect_success response
			expect(assoc.volunteers.include?(volunteer)).to be_falsy
		end
  end

  describe 'invite' do
  	assoc = FactoryGirl.create(:assoc)

  	# members
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")
  	member = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id, rights: "member")

		# non members
  	volunteer = FactoryGirl.create(:volunteer)

  	it "fails to invite because of rights issue" do
  		log member
  		expect { post :invite, { assoc_id: assoc.id, volunteer_id: volunteer.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "fails to invite because already member" do
  		log owner
  		expect { post :invite, { assoc_id: assoc.id, volunteer_id: member.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "successfuly invites a volunteer to join the association" do
  		log owner
  		expect { post :invite, { assoc_id: assoc.id, volunteer_id: volunteer.id } }.to change { Notification.count }.by(1)
  		expect_success response
  	end
  end

  describe 'reply_invite' do
  	assoc = FactoryGirl.create(:assoc)

  	# members
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")

		# non members
  	volunteer = FactoryGirl.create(:volunteer)
  	notification = FactoryGirl.create(:notification, sender_id: owner.id, notif_type: "InviteMember", assoc_id: assoc.id, receiver_id: volunteer.id)

		it "fails to reply invite because of rights issue" do
			log owner
			post :reply_invite, { notif_id: notification.id, acceptance: 'true' }
			expect_failure response
		end

		it "successfuly accepted invitation" do
			log volunteer
			post :reply_invite, { notif_id: notification.id, acceptance: 'true' }

			expect_success response
			expect(assoc.volunteers.include?(volunteer)).to be_truthy
		end

		it "successfuly refused invitation" do
			log volunteer
			post :reply_invite, { notif_id: notification.id, acceptance: 'false' }

			expect_success response
			expect(assoc.volunteers.include?(volunteer)).to be_falsy
		end
  end

  describe 'leave_assoc' do
  	assoc = FactoryGirl.create(:assoc)

  	# member
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id, rights: "member")

  	# non member
  	volunteer = FactoryGirl.create(:volunteer)

  	it "fails to leave association because not member" do
  		log member
  		delete :leave_assoc, { assoc_id: assoc.id }

  		expect_success response
  		expect(assoc.volunteers.include?(member)).to be_falsy
  	end

  	it "successfuly leave the association" do
  		log volunteer
  		delete :leave_assoc, { assoc_id: assoc.id }

  		expect_failure response
  		expect(assoc.volunteers.include?(volunteer)).to be_falsy
  	end
  end

  describe 'invited' do
  	assoc = FactoryGirl.create(:assoc)

  	# owner
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")

  	# invited volunteers
  	guest1 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: owner.id, receiver_id: guest1.id, assoc_id: assoc.id, notif_type: "InviteMember")
  	guest2 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: owner.id, receiver_id: guest2.id, assoc_id: assoc.id, notif_type: "InviteMember")

  	it "successfuly get the list of all invited users" do
  		log owner
  		get :invited, { assoc_id: assoc.id }

  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end

  	it "fails to get the list of all invited users because of rights issues" do
  		log guest1
  		get :invited, { assoc_id: assoc.id }

  		expect_failure response
  	end
  end

  describe 'uninvite' do
  	assoc = FactoryGirl.create(:assoc)

  	# owner
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")

  	# invited volunteer
  	guest = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: owner.id, receiver_id: guest.id, assoc_id: assoc.id, notif_type: "InviteMember")

  	# non invited volunteer
  	volunteer = FactoryGirl.create(:volunteer)

  	it "successfuly uninvite volunteer" do
  		log owner
  		expect { delete :uninvite, { assoc_id: assoc.id, volunteer_id: guest.id } }.to change { Notification.count }.by(-1)
  		expect_success response
  	end

  	it "fails to uninvite volunteer because of rights issues" do
  		log volunteer
  		expect { delete :uninvite, { assoc_id: assoc.id, volunteer_id: guest.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end

  	it "fails to uninvite volunteer because he was not invited" do
  		log owner
  		expect { delete :uninvite, { assoc_id: assoc.id, volunteer_id: volunteer.id } }.to change { Notification.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'unjoin' do
  	assoc = FactoryGirl.create(:assoc)

  	# joining volunteer
  	joiner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: joiner.id, assoc_id: assoc.id, notif_type: "JoinAssoc")

  	# non joining volunteer
  	volunteer = FactoryGirl.create(:volunteer)

  	it "successfuly cancel a join request" do
  		log joiner
  		expect { delete :unjoin, { assoc_id: assoc.id }}.to change { Notification.count }.by(-1)
  		expect_success response
  	end

  	it "fails to cancel a non existing join request" do
  		log volunteer
  		expect { delete :unjoin, { assoc_id: assoc.id }}.to change { Notification.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'waiting' do
  	assoc = FactoryGirl.create(:assoc)

  	# owner
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner")

  	# joining volunteer
  	joiner1 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: joiner1.id, assoc_id: assoc.id, notif_type: "JoinAssoc")
  	joiner2 = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: joiner2.id, assoc_id: assoc.id, notif_type: "JoinAssoc")

  	it "successfuly get the list of joining volunteers" do
  		log owner
  		get :waiting, { assoc_id: assoc.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end

  	it "fails to get the list of joining volunteers because of rights issues" do
  		log joiner1
  		get :waiting, { assoc_id: assoc.id }
			expect_failure response
  	end
  end
end
