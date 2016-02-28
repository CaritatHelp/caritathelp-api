require 'test_helper'

class Notification::InviteMemberTest < ActiveSupport::TestCase
  test "invitemember creation without param" do
    link = Notification::InviteMember.new
    assert_not link.save
  end

  test "invitemember creation without sender assoc id" do
    link = Notification::InviteMember.new
    link.receiver_volunteer_id = 1
    assert_not link.save
  end

  test "invitemember creation with good params" do
    link = Notification::InviteMember.new
    link.sender_assoc_id = 1
    link.receiver_volunteer_id = 1
    assert link.save
  end
end
