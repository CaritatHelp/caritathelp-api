require 'test_helper'

class AvLinkTest < ActiveSupport::TestCase
  test "avlink creation with no param" do
    link = AvLink.new
    assert_not link.save 
  end

  test "avlink creation with only assoc_id" do
    link = AvLink.new
    link.assoc_id = 1
    assert_not link.save 
  end

  test "avlink creation with wrong rights" do
    link = AvLink.new
    link.rights = "yolo"
    link.assoc_id = 1
    link.volunteer_id = 1
    assert_not link.save 
  end

  test "avlink creation with good params" do
    link = AvLink.new
    link.rights = "member"
    link.assoc_id = 1
    link.volunteer_id = 1
    assert link.save 
  end

  test "avlink creation without rights" do
    link = AvLink.new
    link.assoc_id = 1
    link.volunteer_id = 1
    assert link.save 
    assert link.rights.eql? 'member'
  end
end
