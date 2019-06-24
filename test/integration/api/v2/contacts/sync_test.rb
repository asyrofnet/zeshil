require 'test_helper'

class API::V2::Contacts::SyncTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to sync" do
    session1 = auth_sessions(:user1_session1)
    user3 = users(:user3)
    user1 = users(:user1)
    contact = [ {contact_name:"random",phone_number:user3.phone_number} ]
    old_contact = user1.contacts.count

    role_official_user = Role.official
    user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
    official_account_count = User.where("id IN (?)", user_role_ids).where(application_id: user1.application_id).count

    post "/api/v2/contacts/sync",
      params: {:contact => contact},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    target_current_contact = official_account_count+1 #official + the number of object in param
    response_data = JSON.parse(response.body)
    assert_equal target_current_contact,response_data['data'].length
    assert_equal "random", Contact.find_by(user_id:user1.id,contact_id:user3.id).contact_name
    assert_equal target_current_contact, user1.reload.contacts.count - old_contact #because old contact still exist just inactive
    
end

test "sync will not deactivate official" do
  session1 = auth_sessions(:user1_session1)
  
  user1 = users(:user1)
  old_contact = user1.contacts.count
  old_contact_user = user1.contacts.first.contact
  name_param = "hello world"
  contact = [ {contact_name:name_param,phone_number:old_contact_user.phone_number} ]
  

  role_official_user = Role.official
  user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
  official_accounts = User.where("id IN (?)", user_role_ids).where(application_id: user1.application_id)
  official_account_count = official_accounts.count

  post "/api/v2/contacts/sync",
    params: {:contact => contact},
    headers: { 'Authorization' => token_header(session1.jwt_token) }

  assert_equal 200, response.status
  assert_equal Mime[:json], response.content_type
  target_current_contact = official_account_count+1 #official + the number of object in param
  response_data = JSON.parse(response.body)
  assert_equal target_current_contact,response_data['data'].length
  assert_equal name_param, Contact.find_by(user_id:user1.id,contact_id:old_contact_user.id).contact_name
  official_accounts.each do |acc|
    assert_equal true , Contact.find_by(user_id:user1.id,contact_id:acc.id).is_active
  end
  
end

  test "unauthorized will get error" do
    user3 = users(:user3)
    contact = [ {contact_name:"random",phone_number:user3.phone_number} ]
    post "/api/v2/contacts/sync",
      params: {:contact => contact},
      headers: { 'Authorization' => nil }

    assert_equal 401, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Unauthorized Access', response_data['error']['message']

  end

end
