require 'test_helper'

class AssocsControllerTest < ActionController::TestCase
  test "sould get a list of all associations" do
    get :index
    assert_response :success
  end
end
