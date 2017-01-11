require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'create' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)
  	volunteer3 = FactoryGirl.create(:volunteer)

  	# chatroom with volunteer 1 and 3
  	chatroom = FactoryGirl.create(:chatroom, number_volunteers: 2)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer1.id, chatroom_id: chatroom.id)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer3.id, chatroom_id: chatroom.id)

  	it "successfuly create a chatroom with volunteer 1, 2 and 3" do
  		log volunteer1
  		expect { post :create, { name: Faker::Name.name, volunteers: [volunteer2.id, volunteer3.id] } }.to change { Chatroom.count }.by(1).and change { ChatroomVolunteer.count }.by(3)
  		expect_success response
  	end

  	it "fails to create a chatroom with volunteer 1 and 3 because it already exists" do
  		log volunteer1
  		expect { post :create, { name: Faker::Name.name, volunteers: [volunteer3.id] } }.to change { Chatroom.count }.by(0)
  		expect_success response
  	end

  	it "fails to create a chatroom because not enough people" do
  		log volunteer1
  		expect { post :create, { name: Faker::Name.name, volunteers: [volunteer1.id] } }.to change { Chatroom.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'index' do
  	# volunteers
  	volunteer = FactoryGirl.create(:volunteer)

  	# chatroom
  	chatroom = FactoryGirl.create(:chatroom, number_volunteers: 1)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer.id, chatroom_id: chatroom.id)
  	chatroom = FactoryGirl.create(:chatroom, number_volunteers: 1)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer.id, chatroom_id: chatroom.id)
  	chatroom = FactoryGirl.create(:chatroom, number_volunteers: 1)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer.id, chatroom_id: chatroom.id)

  	it "gets a list of all volunteer's chatrooms" do
  		log volunteer
  		get :index
  		body = expect_success response
  		expect(body["response"].length).to eq(3)
  	end
  end

  describe 'participants & show' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)
  	volunteer3 = FactoryGirl.create(:volunteer)

  	# chatroom
  	chatroom = FactoryGirl.create(:chatroom, number_volunteers: 2)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer1.id, chatroom_id: chatroom.id)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer2.id, chatroom_id: chatroom.id)

  	# messages
  	FactoryGirl.create(:message, chatroom_id: chatroom.id, volunteer_id: volunteer1.id)

  	it "gets a list of all chatroom's participants" do
  		log volunteer1
  		get :participants, { id: chatroom.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(2)
  	end

  	it "fails to get a list of all chatroom's participants because of rights issues" do
  		log volunteer3
  		get :participants, { id: chatroom.id }
  		body = expect_failure response
  	end

  	it "successfuly get a chatroom's messages" do
  		log volunteer1
  		get :show, { id: chatroom.id }
  		body = expect_success response
  		expect(body["response"].length).to eq(1)
  		expect(body["response"].first["volunteer_id"]).to eq(volunteer1.id)
  	end

  	it "fails to get a chatroom's messages because of rights issues" do
  		log volunteer3
  		get :show, { id: chatroom.id }
  		body = expect_failure response
  	end
  end

  describe 'set_name & update & new_message' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)
  	volunteer3 = FactoryGirl.create(:volunteer)

  	# chatroom
  	chatroom = FactoryGirl.create(:chatroom, number_volunteers: 2)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer1.id, chatroom_id: chatroom.id)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer2.id, chatroom_id: chatroom.id)

  	it "successfuly set the name of a chatroom" do
  		log volunteer1
  		new_name = Faker::Name.name
  		put :set_name, { id: chatroom.id, name: new_name }
  		body = expect_success response
  		expect(body["response"]["name"]).to eq(new_name)
  	end

  	it "fails to set the name of a chatroom because of rights issues" do
  		log volunteer3
  		old_name = chatroom.name
  		put :set_name, { id: chatroom.id, name: Faker::Name.name }
  		body = expect_failure response
  		expect(chatroom.name).to eq(old_name)
  	end

  	it "successfuly update a chatroom" do
  		log volunteer1
  		new_name = Faker::Name.name
  		put :set_name, { id: chatroom.id, name: new_name, volunteers: [volunteer3.id] }
  		body = expect_success response
  		expect(body["response"]["name"]).to eq(new_name)
  		expect { chatroom.volunteers.include?(volunteer3) }
  	end

  	it "fails to update a chatroom because of rights issues" do
  		log volunteer3
  		old_name = chatroom.name
  		put :set_name, { id: chatroom.id, name: Faker::Name.name }
  		body = expect_failure response
  		expect(chatroom.name).to eq(old_name)
  	end

  	it "successfuly add a message to the chatroom" do
  		log volunteer1
  		expect { put :new_message, { id: chatroom.id, content: Faker::Lorem.sentence } }.to change { Message.count }.by(1)
  		expect(chatroom.messages.count).to eq(1)
  	end

  	it "fails to add a message to the chatroom because of rights issues" do
  		log volunteer3
  		expect { put :new_message, { id: chatroom.id, content: Faker::Lorem.sentence } }.to change { Message.count }.by(0)
  		expect_failure response
  	end

  	it "fails to create a message because of missing params" do
  		log volunteer1
  		expect { put :new_message, { id: chatroom.id } }.to change { Message.count }.by(0)
  		expect_failure response
  	end
  end

  describe 'kick_volunteer & leave & delete_message' do
  	# volunteers
  	volunteer1 = FactoryGirl.create(:volunteer)
  	volunteer2 = FactoryGirl.create(:volunteer)
  	volunteer3 = FactoryGirl.create(:volunteer)
  	volunteer4 = FactoryGirl.create(:volunteer)

  	# chatroom
  	chatroom = FactoryGirl.create(:chatroom, number_volunteers: 2)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer1.id, chatroom_id: chatroom.id)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer2.id, chatroom_id: chatroom.id)
  	FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer3.id, chatroom_id: chatroom.id)

  	# messages
  	message1 = FactoryGirl.create(:message, chatroom_id: chatroom.id, volunteer_id: volunteer1.id)
  	message2 = FactoryGirl.create(:message, chatroom_id: chatroom.id, volunteer_id: volunteer2.id)

  	it "successfuly kicks a volunteer from chatroom" do
  		log volunteer1
  		delete :kick_volunteer, { id: chatroom.id, volunteer_id: volunteer2.id }
			expect_success response
			expect { chatroom.volunteers.exclude?(volunteer2) }
  	end

  	it "fails to kick a volunteer from chatroom because of rights issues" do
  		log volunteer4
  		delete :kick_volunteer, { id: chatroom.id, volunteer_id: volunteer2.id }
			expect_failure response
			expect { chatroom.volunteers.include?(volunteer2) }
  	end

  	it "successfuly leaves a chatroom" do
  		log volunteer1
  		delete :leave, { id: chatroom.id }
			expect_success response
			expect { chatroom.volunteers.exclude?(volunteer1) }
  	end

  	it "fails to leave a chatroom not joined" do
  		log volunteer4
  		delete :leave, { id: chatroom.id }
			expect_failure response
  	end

  	it "successfuly delete a message" do
  		log volunteer1
  		delete :delete_message, { id: chatroom.id, message_id: message1.id }
			expect_success response
			expect { chatroom.messages.exclude?(message1) }
  	end

  	it "fails to delete an inexisting message" do
  		log volunteer1
  		delete :delete_message, { id: chatroom.id, message_id: message1.id + message2.id }
			expect_failure response
  	end

  	it "fails to delete another volunteer's message" do
  		log volunteer1
  		delete :delete_message, { id: chatroom.id, message_id: message2.id }
			expect_failure response
			expect { chatroom.messages.include?(message2) }
  	end
  end
end
