require 'test_helper'

class API::V1::CallsTest < ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  # list of user call logs
  test "user1 attempt to get list of call_logs without access_token" do
    get "/api/v1/calls",
      headers: {}

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']
  end

  test "user1 attempt to get list of call_logs, success" do
    session1 = auth_sessions(:user1_session1)

    get "/api/v1/calls",
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Heru', response_data['data'][0]['caller_user']['fullname']
    assert_equal 'Setiawan', response_data['data'][0]['callee_user']['fullname']
  end

  # post system event message
  test "Unauthorized user attempt to post call system event message" do

    body = {
      :user_email => 'userid_2_6285643123456@qisme.com',
      :user_type => 'callee',
      :call_room_id => 212,
      :is_video => false,
      :call_event => 'incoming',
    }

    post "/api/v1/calls",
      params: body,
      headers: {}

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type
  end

  test "user1 attempt to post call system event message without parameter user_email" do
    session1 = auth_sessions(:user1_session1)

    body = {
      :user_email => '',
      :user_type => 'callee',
      :call_room_id => 212,
      :is_video => false,
      :call_event => 'incoming',
    }

    post "/api/v1/calls",
      params: body,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'user_email cannot be empty.', response_data['error']['message']
  end

  test "user1 attempt to post call system event message without parameter user_type" do
    session1 = auth_sessions(:user1_session1)

    body = {
      :user_email => 'userid_2_6285643123456@qisme.com',
      :user_type => '',
      :call_room_id => 212,
      :is_video => false,
      :call_event => 'incoming',
    }

    post "/api/v1/calls",
      params: body,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "user_type can't be empty.", response_data['error']['message']
  end

  test "user1 attempt to post call system event message without parameter call_room_id" do
    session1 = auth_sessions(:user1_session1)

    body = {
      :user_email => 'userid_2_6285643123456@qisme.com',
      :user_type => 'callee',
      :call_room_id => nil,
      :is_video => false,
      :call_event => 'incoming',
    }

    post "/api/v1/calls",
      params: body,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "call_room_id cannot be empty.", response_data['error']['message']
  end

  test "user1 attempt to post call system event message without parameter is_video" do
    session1 = auth_sessions(:user1_session1)

    body = {
      :user_email => 'userid_2_6285643123456@qisme.com',
      :user_type => 'callee',
      :call_room_id => 54321,
      :is_video => nil,
      :call_event => 'incoming',
    }

    post "/api/v1/calls",
      params: body,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "is_video can't be empty.", response_data['error']['message']
  end

  test "user1 attempt to post call system event message without parameter call_event" do
    session1 = auth_sessions(:user1_session1)

    body = {
      :user_email => 'userid_2_6285643123456@qisme.com',
      :user_type => 'callee',
      :call_room_id => 54321,
      :is_video => false,
      :call_event => '',
    }

    post "/api/v1/calls",
      params: body,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "Call event can't be empty.", response_data['error']['message']
  end

  test "user1 attempt to post call system event message, success" do
    session1 = auth_sessions(:user1_session1)

    body = {
      :user_email => 'userid_2_6285643123456@qisme.com',
      :user_type => 'callee',
      :call_room_id => 212,
      :is_video => false,
      :call_event => 'incoming',
    }

    # mock QiscusSdk#post_system_event_message
    qiscus_sdk = mock('object')
    qiscus_sdk.expects(:post_system_event_message).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/calls",
      params: body,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'call', response_data['data']['system_event_type']
    assert_equal 'Heru', response_data['data']['caller_user']['fullname']
    assert_equal 'Setiawan', response_data['data']['callee_user']['fullname']
    assert_equal 'Heru call Setiawan', response_data['data']['message']
    assert_equal 'incoming', response_data['data']['call_event']
  end

  #admin list of user call logs
  test "non admin user attempt to get list of call_logs admin level" do
    session2 = auth_sessions(:user2_session2)

    get "/api/v1/admin/calls",
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access. User is not admin.', response_data['error']['message']
  end

  test "Unauthorized user attempt to get list of call_logs admin level" do

    get "/api/v1/admin/calls",
      headers: {}

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']
  end

  test "admin attempt to get list of call_logs admin level, success" do
    session1 = auth_sessions(:user1_session1)

    get "/api/v1/admin/calls",
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 4, response_data['meta']['total']
	end

	test "admin attempt to get list of call_logs admin level by date range, success" do
    session1 = auth_sessions(:user1_session1)

    get "/api/v1/admin/calls/?start_date=2018-03-28&end_date=2018-03-28",
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 2, response_data['meta']['total']
	end

	test "user, Heru, attempt to get list of call_logs by date range, success" do
    session1 = auth_sessions(:user1_session1)

    get "/api/v1/calls/?start_date=2018-03-28&end_date=2018-03-28",
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 2, response_data['meta']['total']
	end

	test "user, Heru, attempt to get list of call_logs with only start date, success but not filter by date" do
    session1 = auth_sessions(:user1_session1)

    get "/api/v1/calls/?start_date=2018-03-28",
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 4, response_data['meta']['total']
	end

	test "user, Heru, attempt to get list of call_logs without auth, fail" do

    get "/api/v1/calls/?start_date=2018-03-28"

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type
	end
end
