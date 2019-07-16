require 'test_helper'

class API::V2::Chat::ResponderTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to trigger auto responder" do
    #Make sure official have auto responder
    
    session1 = auth_sessions(:user1_session1)
    useroa1 = users(:useroa1)
    user1 = users(:user1)
    official_id = useroa1.id
    additional_info = useroa1.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_RESPONDER_KEY)
    
    qiscus_sdk = mock('object')
    room_id = 200
    return_body = {chat_room: {room_id: 200, comment_id: 1000} }
    qiscus_sdk.expects(:post_comment).with(useroa1.qiscus_token, room_id.to_s, additional_info.value).returns(return_body)
    QiscusSdk.expects(:new).returns(qiscus_sdk)
    post "/api/v2/chat/auto_responder/trigger",
      params: {:official_id => official_id , :qiscus_room_id => room_id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }
    
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type  
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
    assert_equal return_body.to_json, response_data["data"].to_json
end

test "status fail if no responder" do
    #Make sure official have auto responder
    
    session1 = auth_sessions(:user1_session1)
    useroa1 = users(:user2)
    user1 = users(:user1)
    official_id = useroa1.id
    
    qiscus_sdk = mock('object')
    room_id = 200
    QiscusSdk.expects(:new).never
    post "/api/v2/chat/auto_responder/trigger",
      params: {:official_id => official_id , :qiscus_room_id => room_id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }
    
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type  
    response_data = JSON.parse(response.body)
    assert_equal "fail", response_data["status"]
    assert_equal "No Auto Responder Found", response_data["data"]
end


  test "unauthorized will get error" do
    user3 = users(:user3)
    contact = [ {contact_name:"random",phone_number:user3.phone_number} ]
    post "/api/v2/chat/auto_responder/trigger",
      params: {},
      headers: { 'Authorization' => nil }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']

  end

end
