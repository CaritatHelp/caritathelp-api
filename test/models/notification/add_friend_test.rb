require 'test_helper'

class Notification::AddFriendTest < ActiveSupport::TestCase
  test "addfriend creation without param" do
    link = Notification::AddFriend.new
    assert_not link.save
  end

  test "addfriend creation without sender volunteer id" do
    link = Notification::AddFriend.new
    link.receiver_volunteer_id = 1
    assert_not link.save
  end

  test "addfriend creation with good params" do
    link = Notification::AddFriend.new
    link.sender_volunteer_id = 1
    link.receiver_volunteer_id = 1
    assert link.save
  end
end
