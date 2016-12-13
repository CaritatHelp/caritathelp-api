require 'rails_helper'

RSpec.describe Message, type: :model do
	describe "messages create/update/delete" do
		let(:chatroom) { FactoryGirl.create(:chatroom) }
		let(:volunteer) {FactoryGirl.create(:volunteer) }
		let(:message1) { FactoryGirl.create(:message, volunteer_id: volunteer.id, chatroom_id: chatroom.id) }

		it "creates a new message" do
			expect { Message.create(
				content: Faker::Lorem.sentence,
				volunteer_id: volunteer.id,
				chatroom_id: chatroom.id)}.to change { Message.count }.by(1)
		end

		it "does not create a new message because of missing content" do
			message = Message.create(
				volunteer_id: volunteer.id,
				chatroom_id: chatroom.id)
			expect(message.valid?).to be_falsy
			expect(message.errors.include?(:content)).to be_truthy
		end

		it "updates message" do
			content = Faker::Lorem.sentence
			message1.content = content
			expect(message1.save).to be_truthy
			expect(message1.content).to eq(content)
		end

		it "deletes message" do
			message = FactoryGirl.create(:message, volunteer_id: volunteer.id, chatroom_id: chatroom.id)
			expect { message.destroy }.to change { Message.count }.by(-1)
		end
	end

	describe "message links" do
		let(:chatroom) { FactoryGirl.create(:chatroom) }
		let(:volunteer) {FactoryGirl.create(:volunteer) }
		let(:message1) { FactoryGirl.create(:message, volunteer_id: volunteer.id, chatroom_id: chatroom.id) }
		let(:message2) { FactoryGirl.create(:message, volunteer_id: volunteer.id, chatroom_id: chatroom.id) }

		it "get the message's chatroom" do
			expect(message1.chatroom.id).to eq(chatroom.id)
		end

		it "get the message's volunteer" do
			expect(message1.volunteer.id).to eq(volunteer.id)
		end

		it "get the chatroom's messages" do
			message2
			expect(message1.chatroom.messages.count).to eq(2)
		end
	end
end
