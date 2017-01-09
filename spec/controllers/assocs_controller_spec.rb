require 'rails_helper'

RSpec.describe AssocsController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'index' do
  	FactoryGirl.create(:assoc)

  	it "get a list of existing associations" do
  		get :index
  		body = expect_success response
  		expect(body["response"].length).not_to eq(0)
  	end
  end

  describe 'create' do
  	volunteer = FactoryGirl.create(:volunteer)

  	it "create a new association with minimum params" do
  		log volunteer
  		expect { post :create, { name: Faker::Name.name, description: Faker::Lorem.sentence } }.to change { Assoc.count }.by(1)
  		expect_success response
  	end

  	it "fails to create an association because of missing params" do
  		log volunteer
  		expect { post :create, { name: Faker::Name.name } }.to change { Assoc.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'show' do
  	assoc = FactoryGirl.create(:assoc)
  	volunteer = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: volunteer.id, assoc_id: assoc.id, rights: "owner")

  	it "shows an association's details" do
  		get :show, { id: assoc.id }
  		body = expect_success response
  		expect(body["response"]["id"]).to eq(assoc.id)
  		expect(body["response"]["rights"]).to eq(nil)
  	end

  	it "shows an assocation's details with logged in volunteer's rights" do
  		log volunteer
  		get :show, { id: assoc.id }
  		body = expect_success response
  		expect(body["response"]["id"]).to eq(assoc.id)
  		expect(body["response"]["rights"]).to eq("owner")
  	end
  end

  describe 'members' do
  	assoc = FactoryGirl.create(:assoc)
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: member.id, assoc_id: assoc.id, rights: "member")
  	volunteer = FactoryGirl.create(:volunteer)

  	it "gets a list of all association's members" do
  		log owner
  		get :members, { id: assoc.id }
  		body = expect_success response
  		expect { body["response"].include?(owner) and body["response"].include?(member) and body["response"].exclude?(volunteer) and body["response"].length == 2 }
  	end
  end

  describe 'events' do
  	assoc = FactoryGirl.create(:assoc)
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")
  	event1 = FactoryGirl.create(:event, assoc_id: assoc.id)
  	event2 = FactoryGirl.create(:event, assoc_id: assoc.id)

  	it "gets a list of all association's event" do
  		log owner
  		get :events, { id: assoc.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end
  end

  describe 'update' do
  	assoc = FactoryGirl.create(:assoc)
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: member.id, assoc_id: assoc.id, rights: "member")

  	it "successfuly update association's fields" do
  		log owner
  		new_name = Faker::Name.name
  		put :update, { id: assoc.id, name: new_name }
  		body = expect_success response
  		expect(body["response"]["name"]).to eq(new_name)
  	end

  	it "fails to update association's fields because of rights issues" do
  		log member
  		old_name = assoc.name
  		put :update, { id: assoc.id, name: Faker::Name.name }
  		body = expect_failure response
  		expect(assoc.name).to eq(old_name)
  	end
  end

  describe 'delete' do
  	assoc = FactoryGirl.create(:assoc)
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")
  	member = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: member.id, assoc_id: assoc.id, rights: "member")

  	it "successfuly delete an association" do
  		log owner
  		expect { delete :delete, { id: assoc.id } }.to change { Assoc.count }.by(-1)
  		expect_success response
  	end

  	it "fails to delete an association because of rights issues" do
  		log member
  		expect { delete :delete, { id: assoc.id } }.to change { Assoc.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'invited' do
  	assoc1 = FactoryGirl.create(:assoc)
  	assoc2 = FactoryGirl.create(:assoc)
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc1.id, rights: "owner")
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc2.id, rights: "owner")
  	volunteer = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: owner.id, receiver_id: volunteer.id, assoc_id: assoc1.id, notif_type: "InviteMember")
  	FactoryGirl.create(:notification, sender_id: owner.id, receiver_id: volunteer.id, assoc_id: assoc2.id, notif_type: "InviteMember")

  	it "successfuly get the list of all the associations the volunteer is invited to" do
  		log volunteer
  		get :invited
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(assoc1) and body["response"].include?(assoc2) }
  	end
  end

  describe 'joining' do
  	assoc1 = FactoryGirl.create(:assoc)
  	assoc2 = FactoryGirl.create(:assoc)
  	volunteer = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:notification, sender_id: volunteer.id, assoc_id: assoc1.id, notif_type: "JoinAssoc")
  	FactoryGirl.create(:notification, sender_id: volunteer.id, assoc_id: assoc2.id, notif_type: "JoinAssoc")

  	it "successfuly get the list of all the associations the volunteer is joining" do
  		log volunteer
  		get :joining
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(assoc1) and body["response"].include?(assoc2) }
  	end
  end

  describe 'pictures' do
  	assoc = FactoryGirl.create(:assoc)

  	it "gets a list of all the association's pictures" do
  		get :pictures, { id: assoc.id }
  		body = expect_success response
  	end
  end

  describe 'main_picture' do
  	assoc = FactoryGirl.create(:assoc)

  	it "gets a list of the association main picture" do
  		get :pictures, { id: assoc.id }
  		expect_success response
  	end
  end

  describe 'news' do
  	assoc = FactoryGirl.create(:assoc)

  	# members
  	owner = FactoryGirl.create(:volunteer)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")

  	# non members
  	volunteer = FactoryGirl.create(:volunteer)

  	# public news
  	FactoryGirl.create(:news, group_id: assoc.id, group_type: "Assoc", group_name: assoc.name, group_thumb_path: assoc.thumb_path, as_group: true, volunteer_name: owner.fullname, volunteer_thumb_path: owner.thumb_path, volunteer_id: owner.id)
  	FactoryGirl.create(:news, group_id: assoc.id, group_type: "Assoc", group_name: assoc.name, group_thumb_path: assoc.thumb_path, as_group: true, volunteer_name: owner.fullname, volunteer_thumb_path: owner.thumb_path, volunteer_id: owner.id)

  	# private news
  	FactoryGirl.create(:news, group_id: assoc.id, group_type: "Assoc", group_name: assoc.name, group_thumb_path: assoc.thumb_path, as_group: true, volunteer_name: owner.fullname, volunteer_thumb_path: owner.thumb_path, volunteer_id: owner.id, private: true)

  	it "returns public & private news" do
  		log owner
  		get :news, { id: assoc.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(3)
  	end

  	it "returns only the public news" do
  		log volunteer
  		get :news, { id: assoc.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end
  end

  describe 'shelters' do
  	assoc = FactoryGirl.create(:assoc)

  	# shelters
  	s1 = FactoryGirl.create(:shelter, assoc_id: assoc.id)
  	s2 = FactoryGirl.create(:shelter, assoc_id: assoc.id)

  	it "gets the list of all association's shelters" do
  		get :shelters, { id: assoc.id }
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(s1, s2) }
  	end
  end

  describe 'search' do
  	croix_rouge = FactoryGirl.create(:assoc, name: "Croix rouge")
  	croix_verte = FactoryGirl.create(:assoc, name: "Croix verte")
  	pomme_verte = FactoryGirl.create(:assoc, name: "Pomme verte")

  	it "returns the Croix rouge association" do
  		get :search, { research: "croix rouge" }
  		body = expect_success response
  		expect { body["response"].length == 1 and body["response"].include?(croix_rouge) }
  	end

  	it "returns the Croix rouge & Croix verte associations" do
  		get :search, { research: "croix" }
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(croix_rouge, croix_verte) }
  	end

  	it "returns the Croix verte & Pomme verte associations" do
  		get :search, { research: "verte" }
  		body = expect_success response
  		expect { body["response"].length == 2 and body["response"].include?(croix_verte, pomme_verte) }
  	end

  	it "returns 0 associations" do
  		get :search, { research: "yolo" }
  		body = expect_success response
  		expect(body["response"].length).to eq(0)
  	end

  	it "returns the Croix rouge & Croix verte & Pomme verte associations" do
  		get :search, { research: "r" }
  		body = expect_success response
  		expect { body["response"].length == 3 and body["response"].include?(croix_rouge, croix_verte, pomme_verte) }
  	end
  end
end
