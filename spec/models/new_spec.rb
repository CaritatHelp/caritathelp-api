require 'rails_helper'

RSpec.describe New, type: :model do
	describe "news create/update/delete" do
		assoc = FactoryGirl.create(:assoc)
		owner = FactoryGirl.create(:volunteer)
			link_owner = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner", level: 10)
			news = FactoryGirl.create(:news, volunteer_id: owner.id,
								group_id: assoc.id,
								group_type: "Assoc",
								as_group: true)

			it "creates a news" do
				expect { FactoryGirl.create(:news, volunteer_id: owner.id,
									group_id: assoc.id,
									group_type: "Assoc",
									as_group: true) }
				.to change { New.count }.by(1)
			end

		it "update a news" do
			content = Faker::Lorem.sentence
			news.content = content
			news.save
			expect(news.content).to eq(content)
		end
	end

	describe "news link" do
		assoc = FactoryGirl.create(:assoc)
		owner = FactoryGirl.create(:volunteer)
			link_owner = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner", level: 10)
			news = FactoryGirl.create(:news, volunteer_id: owner.id,
								group_id: assoc.id,
								group_type: "Assoc",
								as_group: true)
			comment1 = FactoryGirl.create(:comment, volunteer_id: owner.id, new_id: news.id)
			comment2 = FactoryGirl.create(:comment, volunteer_id: owner.id, new_id: news.id)

			it "get the correct group" do
				expect(news.group.id).to eq(assoc.id)
			end

			it "get the news' comments" do
				expect(news.comments.count).to eq(2)
			end
	end
end
