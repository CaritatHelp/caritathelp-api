require 'rails_helper'

RSpec.describe CommentController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'create' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)

  	# news
  	news = FactoryGirl.create(:news, group_id: volunteer1.id, group_type: "Volunteer", group_name: volunteer1.fullname, group_thumb_path: volunteer1.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)

  	it "successfuly creates a comment on the news" do
  		log volunteer1
  		expect { post :create, { new_id: news.id, content: Faker::Lorem.sentence } }.to change { Comment.count }.by(1)
  		expect_success response
  	end

  	it "fails to create a comment on the news because of rights issues" do
  		log volunteer2
  		expect { post :create, { new_id: news.id, content: Faker::Lorem.sentence } }.to change { Comment.count }.by(0)
  		expect_failure response
  	end
	end

  describe 'update' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)

  	# news
  	news = FactoryGirl.create(:news, group_id: volunteer1.id, group_type: "Volunteer", group_name: volunteer1.fullname, group_thumb_path: volunteer1.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)

  	# comments
  	comment = FactoryGirl.create(:comment, new_id: news.id, volunteer_id: volunteer1.id)

  	it "successfuly update a comment on the news" do
  		log volunteer1
  		new_content = Faker::Lorem.sentence
  		put :update, { id: comment.id, content: new_content }
  		body = expect_success response
  		expect(body["response"]["content"]).to eq(new_content)
  	end

  	it "fails to update a comment on the news because of rights issues" do
  		log volunteer2
  		old_content = comment.content
  		put :update, { id: comment.id, content: Faker::Lorem.sentence }
  		body = expect_failure response
  		expect(comment.content).to eq(old_content)
  	end
	end

  describe 'show' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)

  	# news
  	news = FactoryGirl.create(:news, group_id: volunteer1.id, group_type: "Volunteer", group_name: volunteer1.fullname, group_thumb_path: volunteer1.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)

  	# comments
  	comment = FactoryGirl.create(:comment, new_id: news.id, volunteer_id: volunteer1.id)

  	it "successfuly shows a comment details" do
  		log volunteer1
  		get :show, { id: comment.id }
  		expect_success response
  	end

  	it "fails to show a comment details because of rights issues" do
  		log volunteer2
  		get :show, { id: comment.id }
  		expect_failure response
  	end
	end

  describe 'delete' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)

  	# news
  	news = FactoryGirl.create(:news, group_id: volunteer1.id, group_type: "Volunteer", group_name: volunteer1.fullname, group_thumb_path: volunteer1.thumb_path, as_group: true, volunteer_name: volunteer1.fullname, volunteer_thumb_path: volunteer1.thumb_path, volunteer_id: volunteer1.id, private: true)

  	# comments
  	comment = FactoryGirl.create(:comment, new_id: news.id, volunteer_id: volunteer1.id)

  	it "successfuly deletes a comment" do
  		log volunteer1
  		expect { delete :delete, { id: comment.id } }.to change { Comment.count }.by(-1)
  		expect_success response
  	end

  	it "fails to delete a comment because of rights issues" do
  		log volunteer2
  		expect { delete :delete, { id: comment.id } }.to change { Comment.count }.by(0)
  		expect_failure response
  	end
	end
end
