require 'test_helper'

class VolunteersControllerTest < ActionController::TestCase
  test "should get a list of volunteers" do
    get :index, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'].size == 6
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

  test "should update volunteer" do
    put :update, :id => 1, :token => 'tokenrobin',
    :firstname => 'toto', :password => 'efzef5484zef'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response']['mail'].eql? 'robin@root.com'
    assert body['response']['firstname'].eql? 'toto'
  end

  test "should get a list of notifications" do
    # get :notifications, :id => 3, :token => 'tokenpierre'
    # assert_response :success
    # body = JSON.parse(response.body)
    # assert body['response']['add_friend'][0]['firstname'].eql? 'nicolas'
  end

  test "should get a list of friends" do
    get :friends, :id => 1, :token => 'tokenrobin'
    assert_response :success
    body = JSON.parse(response.body)
    assert body['response'][0]['firstname'].eql? 'Nicolas'
    assert body['response'][1]['firstname'].eql? 'Aude'
  end
end
