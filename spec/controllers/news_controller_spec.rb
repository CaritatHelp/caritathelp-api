require 'rails_helper'

RSpec.describe NewsController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe '#GET index & show & comments' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)
  	volunteer3 = FactoryGirl.create(:volunteer)

  	# friendship
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer1.id, friend_volunteer_id: volunteer2.id)
  	FactoryGirl.create(:v_friend, volunteer_id: volunteer2.id, friend_volunteer_id: volunteer1.id)

  	# news
  	new1 = FactoryGirl.create(:news, group_id: volunteer1.id, group_type: "Volunteer", group_name: volunteer1.fullname, group_thumb_path: volunteer1.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)
  	new2 = FactoryGirl.create(:news, group_id: volunteer2.id, group_type: "Volunteer", group_name: volunteer2.fullname, group_thumb_path: volunteer2.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)
  	new3 = FactoryGirl.create(:news, group_id: volunteer3.id, group_type: "Volunteer", group_name: volunteer3.fullname, group_thumb_path: volunteer3.thumb_path, as_group: true, volunteer_name: volunteer3.fullname, volunteer_thumb_path: volunteer3.thumb_path, volunteer_id: volunteer3.id, private: true)

  	# comments
  	FactoryGirl.create(:comment, new_id: new1.id, volunteer_id: volunteer1.id)

  	it "gets a list of all news concerning the volunteer1" do
  		log volunteer1
  		get :index
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end

  	it "shows new's details" do
  		log volunteer1
  		get :show, { id: new2.id }
  		body = expect_success response
  	end

  	it "fails to show new's details because of rights issues" do
  		log volunteer1
  		get :show, { id: new3.id }
  		body = expect_failure response
  	end

  	it "shows new's comments" do
  		log volunteer1
  		get :comments, { id: new1.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(1)
  	end

  	it "fails to show new's comments because of rights issues" do
  		log volunteer1
  		get :comments, { id: new3.id }
  		body = expect_failure response
  	end
  end

  describe '#POST wall_message' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)

  	it "successfuly post a wall message" do
  		log volunteer1
  		expect { post :wall_message, { content: Faker::Lorem.sentence, group_id: volunteer1.id, group_type: "Volunteer", news_type: "Status"} }.to change { New.count }.by(1)
  	end

  	it "fails to post a wall message because of missing params" do
  		log volunteer1
  		expect { post :wall_message, { content: Faker::Lorem.sentence, group_type: "Volunteer", news_type: "Status"} }.to change { New.count }.by(0)
  	end

  	it "fails to post a wall message because of rights issues" do
  		log volunteer1
  		expect { post :wall_message, { content: Faker::Lorem.sentence, group_id: volunteer2.id, group_type: "Volunteer", news_type: "Status"} }.to change { New.count }.by(0)
  	end
  end

  describe '#PUT update' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)

  	# news
  	new1 = FactoryGirl.create(:news, group_id: volunteer1.id, group_type: "Volunteer", group_name: volunteer1.fullname, group_thumb_path: volunteer1.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)

  	it "successfuly update the news" do
  		log volunteer1
  		new_title = Faker::Name.name
  		put :update, { id: new1.id, title: new_title }
  		body = expect_success response
  		expect(body["response"]["title"]).to eq(new_title)
  	end

  	it "fails to update the news because of rights issues" do
  		log volunteer2
  		old_title = new1.title
  		put :update, { id: new1.id, title: Faker::Name.name }
  		expect_failure response
  		expect(new1.title).to eq(old_title)
  	end
  end

  describe '#DELETE destroy' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)

  	# news
  	new1 = FactoryGirl.create(:news, group_id: volunteer1.id, group_type: "Volunteer", group_name: volunteer1.fullname, group_thumb_path: volunteer1.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)

  	it "successfuly destroy the news" do
  		log volunteer1
  		expect { delete :destroy, { id: new1.id }}.to change { New.count }.by(-1)
  		expect_success response
  	end

  	it "fails to destroy the news because of rights issues" do
  		log volunteer2
  		expect { delete :destroy, { id: new1.id }}.to change { New.count }.by(0)
  		expect_failure response
  	end
  end
end
