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

  test "user1 can add contacts" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)
    
  
    all_users = User.pluck(:phone_number)
    all_contacts = user1.users.pluck(:phone_number)

    non_contact_number = all_users - all_contacts - [user1.phone_number]

    phone_number = non_contact_number.last
    name = "new account"
    old_contact_count = user1.contacts.count
    json_contact = { :contact => [ { :phone_number => phone_number, :contact_name => name  }] }

    post "/api/v2/contacts/add_or_update",
      params: json_contact,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    for i in 0..response_data["data"].length-1 do
      if response_data["data"][i]["phone_number"] == phone_number
         assert_equal response_data["data"][i]["fullname"],name
      end
    end
    assert_equal 1, user1.reload.contacts.count - old_contact_count
  end

  test "user1 can update contacts" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)
    
    contacts = user1.contacts
    phone_number = contacts.first.contact.phone_number
    name = "old contact new name"
    json_contact = { :contact => [ { :phone_number => phone_number, :contact_name => name  }] }

    post "/api/v2/contacts/add_or_update",
      params: json_contact,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    for i in 0..response_data["data"].length-1 do
      if response_data["data"][i]["phone_number"] == phone_number
         assert_equal response_data["data"][i]["fullname"],name
      end
    end
  end

  test "user1 can remove contacts" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)
    
    contacts = user1.contacts
    phone_number = contacts.first.contact.phone_number
    name = "old contact new name"
    old_contact_count = user1.contacts.where(is_active:true).count
    json_contact = { :phone_number => [  phone_number] }

    post "/api/v2/contacts/remove",
      params: json_contact,
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    response_data = JSON.parse(response.body)
    assert_equal 1,  old_contact_count - user1.reload.contacts.where(is_active:true).count

  end

end