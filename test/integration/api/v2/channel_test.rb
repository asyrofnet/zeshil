require 'test_helper'

class API::V2::ChannelTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 will get channel" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)
    message = "channel channel ditemukan"
    

    
    get "/api/v2/channel/username_to_room_id",
      params: {:username=> "channel"},
      headers: { 'Authorization' => token_header(session1.jwt_token) }
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    assert_equal true, response_data["success"]
    assert_equal message, response_data["message"]
  end

  test "user1 will not get random channel" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)
    message = "channel random tidak ditemukan"
    

    
    get "/api/v2/channel/username_to_room_id",
      params: {:username=> "random"},
      headers: { 'Authorization' => token_header(session1.jwt_token) }
      
    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    assert_equal false, response_data["success"]
    assert_equal message, response_data["message"]
  end

  test "unauthorized will get error" do
   

    get "/api/v2/channel/username_to_room_id",
      params: {:query=> nil},
      headers: { 'Authorization' => "" }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type
    
  end

end