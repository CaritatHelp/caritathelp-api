require 'test_helper'

class VolunteersControllerTest < ActionController::TestCase
  test "should get a list of volunteers" do
    get :index, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'].size == 5
    assert body['response'][2]['mail'].eql? 'pierre@root.com'
  end

  test "should create a volunteer" do
    post :create, mail: 'yo@root.com', password: 'root',
    firstname: 'yo', lastname: 'root'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response']['firstname'].eql? 'yo'
    assert body['response']['lastname'].eql? 'root'
    assert body['response']['mail'].eql? 'yo@root.com'
  end

  test "should get a volunteer information" do
    get :show, :id => 2, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response']['mail'].eql? 'nicolas@root.com'
  end

  test "should get a list of matching volunteers" do
    get :search, :token => 'tokenrobin', :research => 'vasseur'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'][0]['mail'].eql? 'robin@root.com'
  end

  test "should update volunteer" do
    put :update, :id => 2, :token => 'tokenrobin',
    :firstname => 'toto', :password => 'efzef5484zef'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response']['mail'].eql? 'nicolas@root.com'
    assert body['response']['firstname'].eql? 'toto'
  end

  test "should get a list of notifications" do
    get :notifications, :id => 3, :token => 'tokenpierre'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response']['add_friend'][0]['firstname'].eql? 'nicolas'
  end

  test "should get a list of friends" do
    get :friends, :id => 1, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'][0]['firstname'].eql? 'nicolas'
    assert body['response'][1]['firstname'].eql? 'pierre'
  end

  test "should remove friendship" do
    delete :remove_friend, :token => 'tokenrobin', :id => 2
    assert_response :success
    # get :friends, :id => 1, :token => 'tokenrobin'
    # assert_response :success
    # body = JSON.parse(response.body)
    # assert body['response'][0]['firstname'].eql? 'pierre'
  end

  test "should delete volunteer" do
    delete :destroy, :id => 2, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['status'] == 200
  end
end
