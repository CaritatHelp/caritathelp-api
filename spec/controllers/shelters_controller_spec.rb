require 'rails_helper'

RSpec.describe SheltersController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe '#GET index & show & search' do
  	# associations
  	assoc = FactoryGirl.create(:assoc)

  	# shelters
  	shelter = FactoryGirl.create(:shelter, assoc_id: assoc.id, name: "Croix rouge")

  	it "gets a list of all existing shelters" do
  		get :index
  		body = expect_success response
  		expect(body["response"].length).not_to eq(0)
  	end

  	it "successfuly show a shelter's details" do
  		get :show, { id: shelter.id }
  		expect_success response
  	end
  end

  describe '#POST create' do
  	# volunteers
  	owner = FactoryGirl.create(:volunteer)
  	member = FactoryGirl.create(:volunteer)
  	volunteer = FactoryGirl.create(:volunteer)

  	# associations
  	assoc = FactoryGirl.create(:assoc)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")
  	FactoryGirl.create(:av_link, volunteer_id: member.id, assoc_id: assoc.id, rights: "member")

  	it "successfuly creates a shelter" do
  		log owner
  		expect { post :create, { assoc_id: assoc.id, name: Faker::Name.name, address: Faker::Address.street_address, zipcode: Faker::Address.zip, city: Faker::Address.city, total_places: Faker::Number.number(3), free_places: Faker::Number.number(2) } }.to change { Shelter.count }.by(1)
  		expect_success response
  	end

  	it "fails to create a shelter because only member of the association" do
  		log member
  		expect { post :create, { assoc_id: assoc.id, name: Faker::Name.name, address: Faker::Address.street_address, zipcode: Faker::Address.zip, city: Faker::Address.city, total_places: Faker::Number.number(3), free_places: Faker::Number.number(2) } }.to change { Shelter.count }.by(0)
  		expect_failure response
  	end

  	it "fails to create a shelter because not member of the association" do
  		log volunteer
  		expect { post :create, { assoc_id: assoc.id, name: Faker::Name.name, address: Faker::Address.street_address, zipcode: Faker::Address.zip, city: Faker::Address.city, total_places: Faker::Number.number(3), free_places: Faker::Number.number(2) } }.to change { Shelter.count }.by(0)
  		expect_failure response
  	end
  end

  describe '#PUT update' do
  	# volunteers
  	owner = FactoryGirl.create(:volunteer)
  	member = FactoryGirl.create(:volunteer)

  	# associations
  	assoc = FactoryGirl.create(:assoc)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")
  	FactoryGirl.create(:av_link, volunteer_id: member.id, assoc_id: assoc.id, rights: "member")

  	# shelters
  	shelter = FactoryGirl.create(:shelter, assoc_id: assoc.id, name: "Croix rouge")

  	it "successfuly update a shelters information" do
  		log owner
  		new_name = Faker::Name.name
  		put :update, { id: shelter.id, assoc_id: assoc.id, name: new_name }
  		body = expect_success response
  		expect(body["response"]["name"]).to eq(new_name)
  	end

  	it "fails to update a shelters information because of rights issues" do
  		log member
  		old_name = shelter.name
  		put :update, { id: shelter.id, assoc_id: assoc.id, name: Faker::Name.name }
  		body = expect_failure response
  		expect(shelter.name).to eq(old_name)
  	end
  end

  describe '#DELETE delete' do
  	# volunteers
  	owner = FactoryGirl.create(:volunteer)
  	member = FactoryGirl.create(:volunteer)
  	volunteer = FactoryGirl.create(:volunteer)

  	# associations
  	assoc = FactoryGirl.create(:assoc)
  	FactoryGirl.create(:av_link, volunteer_id: owner.id, assoc_id: assoc.id, rights: "owner")
  	FactoryGirl.create(:av_link, volunteer_id: member.id, assoc_id: assoc.id, rights: "member")

  	# shelters
  	shelter = FactoryGirl.create(:shelter, assoc_id: assoc.id, name: "Croix rouge")

  	it "successfuly delete a shelters information" do
  		log owner
  		delete :delete, { id: shelter.id, assoc_id: assoc.id }
  		body = expect_success response
  	end

  	it "fails to delete a shelters information because of rights issues" do
  		log member
  		delete :delete, { id: shelter.id, assoc_id: assoc.id }
  		body = expect_failure response
  	end
  end

  describe '#GET pictures & main_picture' do
  	assoc = FactoryGirl.create(:assoc)
  	shelter = FactoryGirl.create(:shelter, assoc_id: assoc.id)

  	it "gets a list of the shelter's pictures" do
  		get :pictures, { id: shelter.id }
  		expect_success response
  	end

  	it "gets the shelter's main picture" do
  		get :pictures, { id: shelter.id }
  		expect_success response
  	end
  end
end
