require 'test_helper'

class API::V2::Chat::BroadcastTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to broadcast" do
    session1 = auth_sessions(:user1_session1)
    user3 = users(:user3)
    user1 = users(:user1)
    phone_number = [user3.phone_number]
    message = "message"
    broadcast_count = BroadcastMessage.count
    BroadcastMessageJobV2.expects(:perform_later)
    post "/api/v2/chat/send_broadcast",
      params: {:phone_number => phone_number , :message => message},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    assert_equal broadcast_count+1, BroadcastMessage.count   
end


  test "unauthorized will get error" do
    user3 = users(:user3)
    contact = [ {contact_name:"random",phone_number:user3.phone_number} ]
    post "/api/v2/chat/send_broadcast",
      params: {:contact => contact},
      headers: { 'Authorization' => nil }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']

  end

end
