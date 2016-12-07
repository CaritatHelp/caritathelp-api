require 'rails_helper'

RSpec.describe Chatroom, type: :model do
	describe "chatroom create/update/delete" do
		let(:chatroom) { FactoryGirl.create(:chatroom) }

		it "creates a chatroom" do
			expect { FactoryGirl.create(:chatroom) }.to change { Chatroom.count }.by(1)
		end

		it "updates a chatroom" do
			name = Faker::Name.name
			chatroom.name = name
			chatroom.save
			expect(chatroom.name).to eq(name)
		end

		it "delete a chatroom" do
			chatroom = FactoryGirl.create(:chatroom)
			expect { chatroom.destroy }.to change { Chatroom.count }.by(-1)
		end
	end

	describe "chatroom links" do
		chatroom = FactoryGirl.create(:chatroom)
		volunteer = FactoryGirl.create(:volunteer)
		FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer.id, chatroom_id: chatroom.id)

		it "get the id of the first volunteer of the chatroom" do
			expect(chatroom.volunteers.first.id).to eq(volunteer.id)
		end
	end
end
