require 'test_helper'

class Notification::JoinAssocTest < ActiveSupport::TestCase
  test "joinassoc creation without param" do
    link = Notification::JoinAssoc.new
    assert_not link.save
  end

  test "joinassoc creation without sender volunteer id" do
    link = Notification::JoinAssoc.new
    link.receiver_assoc_id = 1
    assert_not link.save
  end

  test "joinassoc creation with good params" do
    link = Notification::JoinAssoc.new
    link.sender_volunteer_id = 1
    link.receiver_assoc_id = 1
    assert link.save
  end
end
