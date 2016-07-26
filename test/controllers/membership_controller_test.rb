require 'test_helper'

class MembershipControllerTest < ActionController::TestCase
  test "should fail to upgrade a follower" do
    put :upgrade, token: 'tokennicolas', assoc_id: 2, volunteer_id: 4
    assert_response :success
    body = JSON.parse(response.body)
    assert body['message'] == "You can't do that with a follower"
  end

  test "should upgrade a volunteer" do
    put :upgrade, token: 'tokenrobin', assoc_id: 1, volunteer_id: 6
    assert_response :success
    body = JSON.parse(response.body)
    assert body['message'] == "Member successfuly upgraded"
  end

  test "should successfuly ask to join association" do
    post :join_assoc, token: 'tokenaude', assoc_id: 2
    assert_response :success
    body = JSON.parse(response.body)
    assert body['message'] == "You successfuly applied to this association"
  end

  test "should fail to join association because already member" do
    post :join_assoc, token: 'tokenrobin', assoc_id: 1
    assert_response :success
    body = JSON.parse(response.body)
    assert body['message'] == "You have already applied in this association or you received an invitation"
  end

  test "should fail to kick a follower" do
    delete :kick, token: 'tokennicolas', assoc_id: 2, volunteer_id: 4
    assert_response :success
    body = JSON.parse(response.body)
    assert body['message'] == "You can't do that with a follower"
  end

  test "should kick a volunteer" do
    delete :kick, token: 'tokenrobin', assoc_id: 1, volunteer_id: 4
    assert_response :success
    body = JSON.parse(response.body)
    assert body['message'] == "Member has been kicked"
  end

end
