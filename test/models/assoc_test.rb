require 'test_helper'

class AssocTest < ActiveSupport::TestCase
  test "assoc creation with no param" do
    assoc = Assoc.new
    assert_not assoc.save
  end

  test "assoc creation with only name" do
    assoc = Assoc.new
    assoc.name = "assoc"
    assert_not assoc.save
  end

  test "assoc creation with only description" do
    assoc = Assoc.new
    assoc.description = "assoc"
    assert_not assoc.save
  end

  test "assoc creation with good param" do
    assoc = Assoc.new
    assoc.name = "assoc"
    assoc.description = "assoc"
    assert assoc.save
  end
end
