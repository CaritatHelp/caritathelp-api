require 'rails_helper'

RSpec.describe Shelter, type: :model do
	describe "shelters create/update/delete" do
		let(:assoc) { FactoryGirl.create(:assoc) }
		let(:shelter) { FactoryGirl.create(:shelter, assoc_id: assoc.id) }

		it "creates a new shelter" do
			expect { Shelter.create(
				name: Faker::Name.name,
				address: Faker::Address.street_address,
				zipcode: Faker::Address.zip,
				city: Faker::Address.city,
				total_places: Faker::Number.number(3),
				free_places: Faker::Number.number(2))}.to change { Shelter.count }.by(1)
		end

		it "does not create a new shelter because there are more free_places than total_places" do
			shelter = Shelter.create(
				name: Faker::Name.name,
				address: Faker::Address.street_address,
				zipcode: Faker::Address.zip,
				city: Faker::Address.city,
				total_places: Faker::Number.number(3),
				free_places: Faker::Number.number(4))
			expect(shelter.valid?).to be_falsy
			expect(shelter.errors.include?(:free_places)).to be_truthy
		end

		it "updates shelter" do
			name = Faker::Name.name
			shelter.name = name
			expect(shelter.save).to be_truthy
			expect(shelter.name).to eq(name)
		end

		it "deletes shelter" do
			shelter = FactoryGirl.create(:shelter, assoc_id: assoc.id)
			expect { shelter.destroy }.to change { Shelter.count }.by(-1)
		end
	end

	describe "shelter links" do
		assoc = FactoryGirl.create(:assoc)
		shelter = FactoryGirl.create(:shelter, assoc_id: assoc.id)

		it "get the shelter's association" do
			expect(shelter.assoc.id).to eq(assoc.id)
		end
	end
end
