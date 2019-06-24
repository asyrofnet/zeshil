require 'test_helper'

class API::V2::ContactsTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 will get his contacts" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)
    
    

    user_count = user1.contacts.count
    role_official_user = Role.official
    user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
    official_account_count = User.where("id IN (?)", user_role_ids).where(application_id: user1.application_id).count
    get "/api/v2/contacts",
      params: {:query=> nil},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    assert_equal user_count+ official_account_count, response_data['meta']['total']
  end

  test "unauthorized will get error" do
   

    get "/api/v2/contacts",
      params: {:query=> nil},
      headers: { 'Authorization' => "" }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type
    
  end

end