require 'rails_helper'

RSpec.describe Assoc, type: :model do
	describe "associations create/update/delete" do
		let(:assoc) { FactoryGirl.create(:assoc) }

		it "creates a new association" do
			expect { Assoc.create(name: Faker::Name.name, description: Faker::Lorem.sentence)}
				.to change { Assoc.count }.by(1)
		end

		it "does not create a new association" do
			expect { Assoc.create(name: Faker::Name.name)}
				.to change { Assoc.count }.by(0)
		end

		it "updates association" do
			name = Faker::Name.name
			assoc.name = name
			expect(assoc.save).to be_truthy
			expect(assoc.name).to eq(name)
		end

		it "deletes associations" do
			to_destroy = Assoc.create(name: Faker::Name.name, description: Faker::Lorem.sentence)
			expect { to_destroy.destroy }.to change { Assoc.count }.by(-1)
		end
	end

	describe "association links" do
		assoc = FactoryGirl.create(:assoc)
		shelter = FactoryGirl.create(:shelter, assoc_id: assoc.id)
		owner = FactoryGirl.create(:volunteer)
		member = FactoryGirl.create(:volunteer)
    	link_owner = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner", level: 10)
    	link_member = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id, rights: "member", level: 5)
    	event = FactoryGirl.create(:event, assoc_id: assoc.id)

    	new1 = FactoryGirl.create(:news, volunteer_id: owner.id,
    									group_id: assoc.id,
    									group_name: assoc.name,
    									group_type: "Assoc",
    									group_thumb_path: assoc.thumb_path,
    									as_group: true,
    									volunteer_name: owner.fullname,
    									volunteer_thumb_path: owner.thumb_path)

    	new2 = FactoryGirl.create(:news, volunteer_id: owner.id,
    									group_id: assoc.id,
    									group_name: assoc.name,
    									group_type: "Assoc",
    									group_thumb_path: assoc.thumb_path,
    									as_group: true,
    									volunteer_name: owner.fullname,
    									volunteer_thumb_path: owner.thumb_path)

    	it "get the association's shelters" do
    		expect(assoc.shelters.count).to eq(1)
    	end

    	it "get the association's volunteers" do
    		expect(assoc.volunteers.count).to eq(2)
    	end

    	it "get the association's events" do
    		expect(assoc.events.count).to eq(1)
    	end

    	it "get the association's news" do
    		expect(assoc.news.count).to eq(2)
    	end
	end
end
