require 'rails_helper'

RSpec.describe Volunteer, type: :model do
	describe "volunteers create/update/delete" do
		let(:volunteer) { FactoryGirl.create(:volunteer) }

		it "creates a new volunteer" do
			expect { Volunteer.create(
				firstname: Faker::Name.first_name,
				lastname: Faker::Name.last_name,
				email: Faker::Internet.email,
				password: "root1234")}.to change { Volunteer.count }.by(1)
		end

		it "does not create a new volunteer because of missing password" do
			volunteer = Volunteer.create(
				firstname: Faker::Name.first_name,
				lastname: Faker::Name.last_name,
				email: Faker::Internet.email)
			expect(volunteer.valid?).to be_falsy
			expect(volunteer.errors.include?(:password))
		end

		it "does not create a new volunteer because of invalid email" do
			volunteer = Volunteer.create(
				firstname: Faker::Name.first_name,
				lastname: Faker::Name.last_name,
				email: "yolo",
				password: "root1234")
			expect(volunteer.valid?).to be_falsy
			expect(volunteer.errors.include?(:email))
		end

		it "updates volunteer" do
			firstname = Faker::Name.first_name
			volunteer.firstname = firstname
			expect(volunteer.save).to be_truthy
			expect(volunteer.fullname).to eq(firstname + " " + volunteer.lastname)
		end

		it "deletes volunteer" do
			volunteer = Volunteer.create(
				firstname: Faker::Name.first_name,
				lastname: Faker::Name.last_name,
				email: Faker::Internet.email,
				password: "root1234")
			expect { volunteer.destroy }.to change { Volunteer.count }.by(-1)
		end
	end

	describe "volunteer links" do
		assoc = FactoryGirl.create(:assoc)
		volunteer = FactoryGirl.create(:volunteer)
			link_owner = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: volunteer.id, rights: "owner", level: 10)
			event = FactoryGirl.create(:event, assoc_id: assoc.id)
			link_host = FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: volunteer.id, rights: "host", level: 10)
		friend1 = FactoryGirl.create(:volunteer)
		friend2 = FactoryGirl.create(:volunteer)
		link_friend1 = FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend1.id)
		link_friend2 = FactoryGirl.create(:v_friend, volunteer_id: volunteer.id, friend_volunteer_id: friend2.id)
		link_friend1_reverse = FactoryGirl.create(:v_friend, volunteer_id: friend1.id, friend_volunteer_id: volunteer.id)
		link_friend2_reverse = FactoryGirl.create(:v_friend, volunteer_id: friend2.id, friend_volunteer_id: volunteer.id)

			new1 = FactoryGirl.create(:news, volunteer_id: volunteer.id,
											group_id: volunteer.id,
											group_name: volunteer.fullname,
											group_type: "Volunteer",
											group_thumb_path: volunteer.thumb_path,
											as_group: true,
											volunteer_name: volunteer.fullname,
											volunteer_thumb_path: volunteer.thumb_path)
			new2 = FactoryGirl.create(:news, volunteer_id: volunteer.id,
											group_id: volunteer.id,
											group_name: volunteer.fullname,
											group_type: "Volunteer",
											group_thumb_path: volunteer.thumb_path,
											as_group: true,
											volunteer_name: volunteer.fullname,
											volunteer_thumb_path: volunteer.thumb_path)


			it "get the volunteer's associations" do
				expect(volunteer.assocs.count).to eq(1)
			end

			it "get the volunteer's events" do
				expect(volunteer.events.count).to eq(1)
			end

			it "get the volunteer's friends" do
				expect(volunteer.volunteers.count).to eq(2)
			end

			it "get the volunteer's news" do
				expect(volunteer.news.count).to eq(2)
			end
	end
end
