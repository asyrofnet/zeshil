require 'test_helper'

class API::V1::Chat::Conversations::ParticipansTest < ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 create group chat with valid target_user_id then add participants" do
    session = auth_sessions(:user1_session1)
    user1 = users(:user1)
    user2 = users(:user2)
    user3 = users(:user3)
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

    # Then user1 add user3 as participants
    qiscus_sdk = mock()
    qiscus_sdk.expects(:add_room_participants)
    # qiscus_sdk.expects(:post_comment)
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    # mock QiscusSdk#post_system_event_message
    qiscus_sdk.expects(:post_system_event_message).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)


    post '/api/v1/chat/conversations/456/participants', 
      params: {:user_id => [user3.id], :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal user3.fullname, response_data['data']['users'][2]['fullname'] 
  end

  test "user1 create group chat with valid target_user_id then delete participants" do
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

    # Then user1 attempt to delete participant 
    qiscus_sdk = mock()
    # mock QiscusSdk#post_system_event_message
    qiscus_sdk.expects(:post_system_event_message).returns([200, {}])

    qiscus_sdk.expects(:remove_room_participants).returns([200, {}])
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    delete '/api/v1/chat/conversations/456/participants', 
      params: {:user_id => [user2.id], :qiscus_room_id => '456'},
      headers: { 'Authorization' => token_header(session.jwt_token) }

    response_data = JSON.parse(response.body)
    assert_equal user3.fullname, response_data['data']['users'][1]['fullname'] 
  end

end