require 'rails_helper'

RSpec.describe Haversine, type: :model do
	describe "Haversine formula" do
		san_francisco_latitude = 37.7749295
		san_francisco_longitude = -122.41941550000001
		versailles_latitude = 48.801408
		versailles_longitude = 2.1301220000000285

		it "returns the haversine distance between San Francisco and Versailles" do
			expect(Haversine.distance(
				san_francisco_latitude,
				san_francisco_longitude,
				versailles_latitude,
				versailles_longitude)).to eq(1.4043773195459464)
		end

		it "convert the distance in km" do
			expect(Haversine.to_km(Haversine.distance(
				san_francisco_latitude,
				san_francisco_longitude,
				versailles_latitude,
				versailles_longitude))).to eq(8947.287902827224)
		end

		it "convert the distance in miles" do
			expect(Haversine.to_miles(Haversine.distance(
				san_francisco_latitude,
				san_francisco_longitude,
				versailles_latitude,
				versailles_longitude))).to eq(5555.716676123764)
		end
	end
end
