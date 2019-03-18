require 'test_helper'

class API::V1::Chat::PinChatsTest < ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to pin chat with not array qiscus room id" do
    session1 = auth_sessions(:user1_session1)
    qiscus_room_id = "123"

    post '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> qiscus_room_id}, # not array qiscus room id
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Qiscus room id must be an array of qiscus room id.', response_data['error']['message']
  end

  test "user1 attempt to pin chat without qiscus room id" do
    session1 = auth_sessions(:user1_session1)

    post '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> []}, # nil qiscus room id
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Qiscus room id must be present.', response_data['error']['message']
  end

  test "user1 attempt to pin chat not listed qiscus room id" do
    session1 = auth_sessions(:user1_session1)
    qiscus_room_ids = 5

    post '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> [qiscus_room_ids]},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Chat room with qiscus_room_id [5] not found.', response_data['error']['message']
  end

  test "user1 attempt to pin chat more than 3 qiscus room id" do
    session1 = auth_sessions(:user1_session1)
    qiscus_room_ids = [22, 234, 25, 221]

    post '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> qiscus_room_ids},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'You can only pin up 3 chats.', response_data['error']['message']
  end

  test "user1 attempt to pin chat that already pinned" do
    session1 = auth_sessions(:user1_session1)
    qiscus_room_ids = [1]

    post '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> qiscus_room_ids},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Chat room with qiscus_room_id [1] already pinned.', response_data['error']['message']
  end

  test "user2 attempt to pin chat room 2, success" do
    session2 = auth_sessions(:user2_session2)
    room2 = chat_rooms(:user2_chatroom200)
    qiscus_room_ids = [room2.qiscus_room_id]

    # mock QiscusSdk#get_rooms_info
    qiscus_sdk = mock('object')
    qiscus_sdk.expects(:get_rooms_info).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> qiscus_room_ids},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 200, response.status
    response_data = JSON.parse(response.body)
    assert_equal room2.qiscus_room_name, response_data['data'][0]['qiscus_room_name']
  end

  test "user1 attempt to destroy pin chat with not array qiscus room id" do
    session1 = auth_sessions(:user1_session1)
    qiscus_room_id = "123"

    delete '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> qiscus_room_id}, # not array qiscus room id
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Qiscus room id must be an array of qiscus room id.', response_data['error']['message']
  end

  test "user1 attempt to destroy pin chat without qiscus room id" do
    session1 = auth_sessions(:user1_session1)

    delete '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> []}, # nil qiscus room id
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Qiscus room id must be present.', response_data['error']['message']
  end

  test "user1 attempt to destroy pin chat qith invalid qiscus room id" do
    session1 = auth_sessions(:user1_session1)
    qiscus_room_ids = 5

    delete '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> [qiscus_room_ids]},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Invalid chat room with qiscus_room_id [5].', response_data['error']['message']
  end

  test "user1 attempt to destroy not pinned chat" do
    session1 = auth_sessions(:user1_session1)
    qiscus_room_ids = 2

    delete '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> [qiscus_room_ids]},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Chat room with qiscus_room_id [2] is not pin chats.', response_data['error']['message']
  end

  test "user1 attempt to destroy pin chat 1, success" do
    session1 = auth_sessions(:user1_session1)
    room1 = chat_rooms(:user1_chatroom100)
    qiscus_room_ids = [room1.qiscus_room_id]

    delete '/api/v1/chat/conversations/pin_chats',
      params: {:qiscus_room_id=> qiscus_room_ids},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    response_data = JSON.parse(response.body)
    assert_equal room1.qiscus_room_name, response_data['data'][0]['qiscus_room_name']
  end
end