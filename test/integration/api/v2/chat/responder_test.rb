require 'test_helper'

class API::V2::Chat::ResponderTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }


  test "Official Account can update auto responder and starter" do
    useroa1 = users(:useroa1)
    auto_responder = "Hello this is respond"
    auto_starter = "Hello this is starter"
    session_oa = auth_sessions(:useroa_sessionoa)
    post "/api/v2/chat/auto_responder/",
      params: {:auto_responder => auto_responder, :auto_starter => auto_starter },
      headers: { 'Authorization' => token_header(session_oa.jwt_token) }
      
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    #assert DB updated
    assert_equal useroa1.reload.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_RESPONDER_KEY).value, auto_responder
    assert_equal useroa1.reload.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_STARTER_KEY).value, auto_starter
    response_data = JSON.parse(response.body)
    auto_responder_data = useroa1.user_additional_infos.where(key: [UserAdditionalInfo::AUTO_RESPONDER_KEY,UserAdditionalInfo::AUTO_STARTER_KEY])
    #assert data is the same
    assert_equal 2, response_data["data"].length
    assert_equal auto_responder_data.to_json, response_data["data"].to_json
  end

  test "Official Account can update only auto responder" do
    useroa1 = users(:useroa1)
    auto_responder = "Hello this is respond"
    auto_starter = "Hello this is starter"
    session_oa = auth_sessions(:useroa_sessionoa)
    post "/api/v2/chat/auto_responder/",
      params: {:auto_responder => auto_responder, },
      headers: { 'Authorization' => token_header(session_oa.jwt_token) }
      
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    #assert DB updated
    assert_equal useroa1.reload.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_RESPONDER_KEY).value, auto_responder
    response_data = JSON.parse(response.body)
    auto_responder_data = useroa1.user_additional_infos.where(key: [UserAdditionalInfo::AUTO_RESPONDER_KEY,UserAdditionalInfo::AUTO_STARTER_KEY])
    #assert data is the same
    assert_equal auto_responder_data.to_json, response_data["data"].to_json
  end

  test "Official Account can update only auto starter" do
    useroa1 = users(:useroa1)
    auto_responder = "Hello this is respond"
    auto_starter = "Hello this is starter"
    session_oa = auth_sessions(:useroa_sessionoa)
    post "/api/v2/chat/auto_responder/",
      params: {:auto_starter => auto_starter, },
      headers: { 'Authorization' => token_header(session_oa.jwt_token) }
      
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    #assert DB updated
    assert_equal useroa1.reload.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_STARTER_KEY).value, auto_starter
    response_data = JSON.parse(response.body)
    auto_responder_data = useroa1.user_additional_infos.where(key: [UserAdditionalInfo::AUTO_RESPONDER_KEY,UserAdditionalInfo::AUTO_STARTER_KEY])
    #assert data is the same
    assert_equal auto_responder_data.to_json, response_data["data"].to_json
  end

  test "non Official Account cannot update auto responder" do
    useroa1 = users(:user1)
    auto_responder = "Hello this is respond"
    auto_starter = "Hello this is starter"
    session_1 = auth_sessions(:user1_session1)
    post "/api/v2/chat/auto_responder/",
      params: {:auto_responder => auto_responder, :auto_starter => auto_starter },
      headers: { 'Authorization' => token_header(session_1.jwt_token) }
      
    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    assert_equal "Only Official can update auto responder", response_data['error']['message']
    
  end

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

test "Official Account can delete auto responder and starter" do
    useroa1 = users(:useroa1) #already have auto responder and starter
    auto_responder_old_data_count = useroa1.user_additional_infos.where(key: [UserAdditionalInfo::AUTO_RESPONDER_KEY,UserAdditionalInfo::AUTO_STARTER_KEY]).count
    
    session_oa = auth_sessions(:useroa_sessionoa)
    post "/api/v2/chat/auto_responder/delete",
      params: {:delete => "both" },
      headers: { 'Authorization' => token_header(session_oa.jwt_token) }
      
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    #assert DB updated
    auto_responder_data_count = useroa1.user_additional_infos.where(key: [UserAdditionalInfo::AUTO_RESPONDER_KEY,UserAdditionalInfo::AUTO_STARTER_KEY]).count
    assert_equal 2,  auto_responder_old_data_count - auto_responder_data_count
    assert_equal "success delete both", response_data["status"]
  end


  test "unauthorized trigger will get error" do
    post "/api/v2/chat/auto_responder/trigger",
      params: {},
      headers: { 'Authorization' => nil }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']

  end

  test "unauthorized update will get error" do
    post "/api/v2/chat/auto_responder/",
      params: {},
      headers: { 'Authorization' => nil }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']

  end

  test "unauthorized delete will get error" do
    post "/api/v2/chat/auto_responder/delete",
      params: {},
      headers: { 'Authorization' => nil }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']

  end

end
