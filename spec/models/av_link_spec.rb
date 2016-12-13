require 'rails_helper'

RSpec.describe AvLink, type: :model do
	describe "link between volunteer and association" do
		assoc = FactoryGirl.create(:assoc)
		member = FactoryGirl.create(:volunteer)
			link_member = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id, rights: "member", level: 5)

		it "upgrade volunteer" do
			link_member.rights = "admin"
			link_member.save
			expect(link_member.level).to eq(8)
		end

		it "downgrade volunteer" do
			link_member.rights = "member"
			link_member.save
			expect(link_member.level).to eq(5)
		end

		it "get the correct volunteer and association" do
			expect(link_member.assoc.id).to eq(assoc.id)
			expect(link_member.volunteer.id).to eq(member.id)
		end
	end
end
