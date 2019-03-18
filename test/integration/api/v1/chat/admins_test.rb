require 'test_helper'

class API::V1::Chat::AdminsTest < ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "admin candidates must be member of group" do
    session1 = auth_sessions(:user1_session1)
    user3 = users(:user3)
    qiscus_room_id = "2"
    user_id = [user3.id]

    post "/api/v1/chat/conversations/#{qiscus_room_id}/admins",
      params: {:user_id=> user_id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'You are not member of this group.', response_data['error']['message']
  end

  test "not admin user attempt to add admin" do
    session2 = auth_sessions(:user2_session2)
    user4 = users(:user4)
    qiscus_room_id = "2"
    user_id = [user4.id]

    post "/api/v1/chat/conversations/#{qiscus_room_id}/admins",
      params: {:user_id=> user_id},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'You are not admin of this group. Only admin can add new group admin.', response_data['error']['message']
  end

  test "user attempt to add admin without input user_id" do
    session3 = auth_sessions(:user3_session3)
    qiscus_room_id = "2"

    post "/api/v1/chat/conversations/#{qiscus_room_id}/admins",
      params: {:user_id=> nil},
      headers: { 'Authorization' => token_header(session3.jwt_token) }

    assert_equal 422, response.status
    response_data = JSON.parse(response.body)
    assert_equal 'Array of user id or qiscus email must be present.', response_data['error']['message']
  end

  test "user1 create group chat with valid target_user_id then add admin" do
    session = auth_sessions(:user1_session1)
    user1 = users(:user1)
    user2 = users(:user2)
    target = [user2.id]

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

    # Ensure that user1 and user2 are group participants
    get '/api/v1/chat/conversations/456/participants',
      params: {:target_user_id=> target, :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)

    assert_equal user1.fullname, response_data['data'][0]['fullname']
    assert_equal user2.fullname, response_data['data'][1]['fullname']

    # mock QiscusSdk#post_system_event_message
    qiscus_sdk.expects(:post_system_event_message).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    # user1 add user2 as admin
    post '/api/v1/chat/conversations/456/admins',
      params: {:user_id => [user2.id], :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    assert_equal 200, response.status
    response_data = JSON.parse(response.body)
    assert_equal user2.fullname, response_data['data'][0]['fullname']
  end
end