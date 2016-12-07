require 'rails_helper'

RSpec.describe ChatroomVolunteer, type: :model do
	describe "ChatroomVolunteer link create/destroy" do
		let(:chatroom) { FactoryGirl.create(:chatroom) }
		let(:volunteer) { FactoryGirl.create(:volunteer) }

		it "creates a link" do
			expect { ChatroomVolunteer.create(volunteer_id: volunteer.id, chatroom_id: chatroom.id) }
				.to change{ chatroom.volunteers.count }.by(1)
		end

		it "destroy a link" do
			link = ChatroomVolunteer.create(volunteer_id: volunteer.id, chatroom_id: chatroom.id)
			expect { link.destroy }.to change { chatroom.volunteers.count }.by(-1)
		end
	end

	describe "chatroom_volunteers links" do
		chatroom = FactoryGirl.create(:chatroom)
		volunteer = FactoryGirl.create(:volunteer)
		link = FactoryGirl.create(:chatroom_volunteer, volunteer_id: volunteer.id, chatroom_id: chatroom.id)

		it "get correct chatroom and volunteer from link" do
			expect(link.volunteer.id).to eq(volunteer.id)
			expect(link.chatroom.id).to eq(chatroom.id)
		end
	end
end
