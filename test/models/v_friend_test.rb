require 'test_helper'

class VFriendTest < ActiveSupport::TestCase
  test "vfriend creation without param" do
    link = VFriend.new
    assert_not link.save
  end

  test "vfriend creation without current volunteer id" do
    link = VFriend.new
    link.friend_volunteer_id = 1
    assert_not link.save
  end

  test "vfriend creation with good params" do
    link = VFriend.new
    link.volunteer_id = 1
    link.friend_volunteer_id = 6
    assert link.save
  end
end
