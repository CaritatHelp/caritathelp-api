require 'rails_helper'

RSpec.describe Comment, type: :model do
	describe "comment create/update" do
		assoc = FactoryGirl.create(:assoc)
		owner = FactoryGirl.create(:volunteer)
			link_owner = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner", level: 10)
			news = FactoryGirl.create(:news, volunteer_id: owner.id,
											group_id: assoc.id,
											group_type: "Assoc",
											as_group: true)
			comment = FactoryGirl.create(:comment, volunteer_id: owner.id, new_id: news.id)

			it "creates a comment" do
				expect { FactoryGirl.create(:comment, volunteer_id: owner.id, new_id: news.id) }.to change{ news.comments.count }.by(1)
			end

			it "updates a comment" do
				content = Faker::Lorem.sentence
				comment.content = content
				comment.save
				expect(comment.content).to eq(content)
			end
	end

	describe "comment links" do
		assoc = FactoryGirl.create(:assoc)
		owner = FactoryGirl.create(:volunteer)
			link_owner = FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id, rights: "owner", level: 10)
			news = FactoryGirl.create(:news, volunteer_id: owner.id,
											group_id: assoc.id,
											group_type: "Assoc",
											as_group: true)
			comment = FactoryGirl.create(:comment, volunteer_id: owner.id, new_id: news.id)

		it "get the correct writer and news from comment" do
			expect(comment.volunteer.id).to eq(owner.id)
			expect(comment.new.id).to eq(news.id)
		end
	end
end
