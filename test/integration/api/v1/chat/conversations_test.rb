require 'test_helper'

class API::V1::Chat::ConversationsTest < ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "conversation list should not be empty" do
    session = auth_sessions(:user1_session1)

    # mock QiscusSdk#get_rooms_info
    qiscus_sdk = mock('object')
    qiscus_sdk.expects(:get_rooms_info).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    # Please note that this may return data from redis cache in second call and expires in certain time
    get '/api/v1/chat/conversations', params: {},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_not_equal [], response_data['data'].to_a # should not empty chat room
    assert_equal response_data['meta']['total'], response_data['data'].to_a.count # meta and data is must the same
  end

  test "user1 create single chat with blank target user id" do
    session = auth_sessions(:user1_session1)

    post '/api/v1/chat/conversations',
      params: {:target_user_id=> ''}, # blank target_user_id
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal 'Target user id can not be blank.', response_data['error']['message']
  end

  test "user1 create single chat with user1" do
    session = auth_sessions(:user1_session1)
    user1 = users(:user1)

    post '/api/v1/chat/conversations',
      params: {:target_user_id=> user1.id}, # user1 is creator and target
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal 'You can not chat only with yourself.', response_data['error']['message']
  end

  test "user1 create single chat with user2 but with empty qiscus_room_id" do
    session = auth_sessions(:user1_session1)
    user2 = users(:user2)

    post '/api/v1/chat/conversations',
      params: {:target_user_id=> user2.id},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    # assert_equal 'Qiscus room id can not be blank.', response_data['error']['message']
  end

  test "user1 create single chat with user2 and valid params" do
    session = auth_sessions(:user1_session1)
    user1 = users(:user1)
    user2 = users(:user2)

    # mock QiscusSdk#rest_get_or_create_room_with_target
    qiscus_sdk = mock('object')
    qiscus_sdk.expects(:get_or_create_room_with_target_rest).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post '/api/v1/chat/conversations',
      params: {:target_user_id=> user2.id, :qiscus_room_id => '123'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)

    # Ensure user1 is creator
    # assert_equal  user1.fullname, response_data['data']['creator']['fullname']

    # Ensure user2 is target
    # assert_equal  user2.fullname, response_data['data']['target']['fullname']
  end

  test "user1 create group chat with target_user not in array" do
    session = auth_sessions(:user1_session1)

    post '/api/v1/chat/conversations/group_chat',
      params: {:target_user_id=> ''}, # Target_user_id not in array
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal  'Target user id must be an array of user id.', response_data['error']['message']
  end

  test "user1 create group chat with blank qiscus room id" do
    session = auth_sessions(:user1_session1)
    user2 = users(:user2)
    target = [user2.id]

    post '/api/v1/chat/conversations/group_chat',
      params: {:target_user_id=> target},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    # assert_equal  'Qiscus room id can not be blank.', response_data['error']['message']
  end

  test "user1 create group chat with valid target_user_id" do
    session = auth_sessions(:user1_session1)
    user1 = users(:user1)
    user2 = users(:user2)
    user3 = users(:user3)
    target = [user2.id, user3.id]

    # mock QiscusSdk#post_system_event_message
    qiscus_sdk = mock('object')
    qiscus_sdk.expects(:post_system_event_message).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post '/api/v1/chat/conversations/group_chat',
      params: {:target_user_id=> target, :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)

    assert_equal user1.fullname, response_data['data']['creator']['fullname'] # ensure creator user
    assert_equal user2.fullname, response_data['data']['users'][1]['fullname'] # ensure target user

    # Ensure that user1, user2, and user3 are participants
    get '/api/v1/chat/conversations/456/participants',
      params: {:target_user_id=> target, :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal user1.fullname, response_data['data'][0]['fullname']
    assert_equal user2.fullname, response_data['data'][1]['fullname']
    assert_equal user3.fullname, response_data['data'][2]['fullname']
  end

  # Channel
  test "user1 create channel chat with target_user not in array" do
    session = auth_sessions(:user1_session1)

    post '/api/v1/chat/conversations/channel',
      params: {:target_user_id=> ''}, # Target_user_id not in array
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal  'Target user id must be an array of user id.', response_data['error']['message']
  end

  test "user1 create channel chat with blank qiscus room id" do
    session = auth_sessions(:user1_session1)
    user2 = users(:user2)
    target = [user2.id]

    post '/api/v1/chat/conversations/channel',
      params: {:target_user_id=> target},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    # assert_equal  'Qiscus room id can not be blank.', response_data['error']['message']
  end

  test "user1 create channel with valid target_user_id" do
    session = auth_sessions(:user1_session1)
    user1 = users(:user1)
    user2 = users(:user2)
    user3 = users(:user3)
    target = [user2.id, user3.id]

    # mock QiscusSdk#post_system_event_message
    qiscus_sdk = mock('object')
    qiscus_sdk.expects(:post_system_event_message).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post '/api/v1/chat/conversations/channel',
      params: {:target_user_id=> target, :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)

    assert_equal user1.fullname, response_data['data']['creator']['fullname'] # ensure creator user
    assert_equal user2.fullname, response_data['data']['users'][1]['fullname'] # ensure target user

    # Ensure that user1, user2, and user3 are participants
    get '/api/v1/chat/conversations/456/participants',
      params: {:target_user_id=> target, :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal user1.fullname, response_data['data'][0]['fullname']
    assert_equal user2.fullname, response_data['data'][1]['fullname']
    assert_equal user3.fullname, response_data['data'][2]['fullname']
  end

end
