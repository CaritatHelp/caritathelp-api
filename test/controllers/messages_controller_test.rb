require 'test_helper'

class MessagesControllerTest < ActionController::TestCase
  test "should get a list of chatrooms" do
    get :index, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'].size == 2
    assert body['response'][1]['name'] == 'Aude - Rob'
    assert body['response'][1]['number_volunteers'] == 2
  end

  test "should get a list of chatroom's members" do
    get :participants, :token => 'tokenrobin', :id => 2
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'].size == 2
    assert body['response'][1]['firstname'] == 'Aude'
  end

  test "should get a messages of a chatroom" do
    get :show, :token => 'tokenrobin', :id => 2
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'].size == 5
    assert body['response'][4]['content'] == "T'es moche"
  end

  test "should change name of the chatroom" do
    put :set_name, :token => 'tokenrobin', :id => 2, :name => "toto"
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response']['name'] == "toto"
  end

  test "should add people to chatroom" do
    put :add_volunteers, :token => 'tokenrobin', :id => 2, :volunteers => ['2']
    assert_response :success
    body = JSON.parse(response.body)

    get :index, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'].size == 2
  end

  test "should kick volunteer from chatroom" do
    delete :kick_volunteer, :token => 'tokenrobin', :id => 2, :volunteer_id => 2
    assert_response :success
    body = JSON.parse(response.body)

    get :index, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'].size == 2
    assert body['response'][1]['number_volunteers'] == 2
  end

  
end
