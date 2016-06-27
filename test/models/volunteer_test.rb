require 'test_helper'

class VolunteerTest < ActiveSupport::TestCase
  test "volunteer creation with no param" do
    volunteer = Volunteer.new
    assert_not volunteer.save, "Should have mail, password, firstname & lastname"
  end

  test "volunteer creation with only mail" do
    volunteer = Volunteer.new
    volunteer.mail = "test@test.com"
    assert_not volunteer.save, "Should have password, firstname & lastname"
  end

  test "volunteer creation with only mail and password" do
    volunteer = Volunteer.new
    volunteer.mail = "test@test.com"
    volunteer.password = "testtest42"
    assert_not volunteer.save, "Should have firstname & lastname"
  end

  test "volunteer creation with only mail password and firstname" do
    volunteer = Volunteer.new
    volunteer.mail = "test@test.com"
    volunteer.password = "testtest42"
    volunteer.firstname = "rob"
    assert_not volunteer.save, "Should have lastname"
  end

  test "volunteer creation with mail password firstname and lastname" do
    volunteer = Volunteer.new
    volunteer.mail = "test@test.com"
    volunteer.password = "testtest42"
    volunteer.firstname = "rob"
    volunteer.lastname = "root"
    assert volunteer.save
  end

  test "volunteer creation with invalid mail" do
    volunteer = Volunteer.new
    volunteer.mail = "test@"
    volunteer.password = "testtest42"
    volunteer.firstname = "rob"
    volunteer.lastname = "root"
    assert_not volunteer.save, "Mail should be"
  end

  test "volunteer creation with wrong gender and allowgps" do
    volunteer = Volunteer.new
    volunteer.mail = "test@test.com"
    volunteer.password = "testtest42"
    volunteer.firstname = "rob"
    volunteer.lastname = "root"
    volunteer.gender = "yo"
    volunteer.allowgps = nil
    assert_not volunteer.save
  end

end
