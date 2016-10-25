require 'rails_helper'

RSpec.describe MembershipController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'PUT #upgrade' do
    let(:assoc) { FactoryGirl.create(:assoc) }
    let(:owner) { FactoryGirl.create(:volunteer) }
    let(:member) { FactoryGirl.create(:volunteer) }
    let(:follower) { FactoryGirl.create(:volunteer) }
    let(:link_owner) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id,
                                          rights: "owner", level: 10) }
    let(:link_member) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id,
                                           rights: "member", level: 5) }
    let(:link_follow) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: follower.id,
                                           rights: "follower", level: 0) }
    
    before do
      set_header(link_owner.volunteer.create_new_auth_token)
    end

    it "fails to upgrade a follower" do
      put :upgrade, { assoc_id: assoc.id, volunteer_id: follower.id }
      body = JSON.parse(response.body)
      expect(link_follow.rights).to eql("follower")
    end

    it "upgrades a volunteer" do
      put :upgrade, { assoc_id: assoc.id, volunteer_id: link_member.volunteer.id, rights: "admin" }
      body = JSON.parse(response.body)
      expect(body["status"]).to eql(200)
    end
  end

  describe 'POST #join_assoc' do
    let(:assoc) { FactoryGirl.create(:assoc) }
    let(:non_member) { FactoryGirl.create(:volunteer) }
    let(:member) { FactoryGirl.create(:volunteer) }
    let(:link_member) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id,
                                           rights: "member", level: 5) }
    
    it "ask to join association" do
      set_header(non_member.create_new_auth_token)
      expect { post :join_assoc, { assoc_id: assoc.id } }.to change { Notification.count }.by(1)
    end

    it "fail to join association because already member" do
      set_header(link_member.volunteer.create_new_auth_token)
      expect { post :join_assoc, { assoc_id: assoc.id } }.to change { Notification.count }.by(0)
    end
  end

  describe 'DELETE #kick' do
    let(:assoc) { FactoryGirl.create(:assoc) }
    let(:owner) { FactoryGirl.create(:volunteer) }
    let(:member) { FactoryGirl.create(:volunteer) }
    let(:follower) { FactoryGirl.create(:volunteer) }
    let(:link_owner) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: owner.id,
                                          rights: "owner", level: 10) }
    let(:link_member) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: member.id,
                                           rights: "member", level: 5) }
    let(:link_follow) { FactoryGirl.create(:av_link, assoc_id: assoc.id, volunteer_id: follower.id,
                                           rights: "follower", level: 0) }

    before do
      set_header(link_owner.volunteer.create_new_auth_token)      
    end
    
    it "fails to kick a follower" do
      delete :kick, { assoc_id: assoc.id, volunteer_id: link_follow.volunteer.id }
      body = JSON.parse(response.body)
      expect(body["status"]).to eql(400)
    end

    it "kicks a volunteer" do
      delete :kick, { assoc_id: assoc.id, volunteer_id: link_member.volunteer.id }
      body = JSON.parse(response.body)
      expect(body["status"]).to eql(200)
    end
  end  
end
