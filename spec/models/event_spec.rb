require 'rails_helper'

RSpec.describe Event, type: :model do
	describe "events create/update/delete" do
		let(:assoc) { FactoryGirl.create(:assoc) }
		let(:event) { FactoryGirl.create(:event, assoc_id: assoc.id) }

		it "creates a new event" do
			expect { Event.create(title: Faker::Name.name, description: Faker::Lorem.sentence,
								begin: Faker::Date.between(1.day.from_now, 2.days.from_now),
								end: Faker::Date.between(3.day.from_now, 4.days.from_now),
								assoc_id: assoc.id)}
				.to change { Event.count }.by(1)
		end

		it "does not create a new event because of missing dates" do
			expect { Event.create(title: Faker::Name.name, description: Faker::Lorem.sentence, assoc_id: assoc.id)}
				.to change { Event.count }.by(0)
		end

		it "does not create a new event because of wrong dates" do
			expect { Event.create(title: Faker::Name.name, description: Faker::Lorem.sentence,
				begin: Faker::Date.between(1.day.from_now, 2.days.from_now),
				end: Faker::Date.backward(5),
				assoc_id: assoc.id)}.to change { Event.count }.by(0)
		end

		it "updates event" do
			title = Faker::Name.name
			event.title = title
			expect(event.save).to be_truthy
			expect(event.title).to eq(title)
		end

		it "does not update event because of wrong end date" do
			event.end = Faker::Date.backward(5)
			expect(event.save).to be_falsy
			expect(event.errors.messages.include?(:end)).to be_truthy
		end

		it "deletes event" do
			to_destroy = Event.create(title: Faker::Name.name, description: Faker::Lorem.sentence,
				begin: Faker::Date.between(1.day.from_now, 2.days.from_now),
				end: Faker::Date.between(3.day.from_now, 4.days.from_now),
				assoc_id: assoc.id)
			expect { to_destroy.destroy }.to change { Event.count }.by(-1)
		end
	end

	describe "event links" do
		assoc = FactoryGirl.create(:assoc)
			event = FactoryGirl.create(:event, assoc_id: assoc.id)
		host = FactoryGirl.create(:volunteer)
		guest = FactoryGirl.create(:volunteer)
			link_host = FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: host.id, rights: "host", level: 10)
			link_guest = FactoryGirl.create(:event_volunteer, event_id: event.id, volunteer_id: guest.id, rights: "member", level: 5)

			new1 = FactoryGirl.create(:news, volunteer_id: host.id,
											group_id: event.id,
											group_type: "Event",
											as_group: true)

			new2 = FactoryGirl.create(:news, volunteer_id: host.id,
											group_id: event.id,
											group_type: "Event",
											as_group: true)

			it "get the event's volunteers" do
				expect(event.volunteers.count).to eq(2)
			end

			it "get the event's association" do
				expect(event.assoc.id).to eq(assoc.id)
			end

			it "get the event's news" do
				expect(event.news.count).to eq(2)
			end
	end
end
