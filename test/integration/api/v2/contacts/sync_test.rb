require 'test_helper'

class API::V2::Contacts::SyncTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to sync" do
    session1 = auth_sessions(:user1_session1)
    user3 = users(:user3)
    user1 = users(:user1)
    contact = [ {contact_name:"random",phone_number:user3.phone_number} ]
    old_contact = user1.contacts.where(is_active:true).count
    
    post "/api/v2/contacts/sync",
      params: {:contact => contact},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    
    target_current_contact = old_contact+contact.length #the number of object in param
    response_data = JSON.parse(response.body)
    
    assert_equal contact.length,response_data['data'].length
    assert_equal "random", Contact.find_by(user_id:user1.id,contact_id:user3.id).contact_name
    
    assert_equal target_current_contact, user1.reload.contacts.count #because old contact still exist just inactive
    
end

test "sync will not deactivate bot" do
  session1 = auth_sessions(:user1_session1)
  
  user1 = users(:user1)
  old_contact = user1.contacts.count
  old_contact_user = user1.contacts.first.contact
  bot = Role.bot
  UserRole.create(role_id: bot.id, user_id: old_contact_user.id)

  name_param = "hello world"
  #WE WILL USE RANDOM PHONE NUMBER
  random_phone_number = old_contact_user.phone_number+"1"
  contact = [ {contact_name:name_param,phone_number: random_phone_number} ] 
  assert_nil User.find_by(phone_number: random_phone_number)
  
  post "/api/v2/contacts/sync",
    params: {:contact => contact},
    headers: { 'Authorization' => token_header(session1.jwt_token) }

  assert_equal 200, response.status
  assert_equal Mime[:json], response.content_type
  response_data = JSON.parse(response.body)
  assert_equal old_contact,response_data['data'].length
  assert_equal old_contact_user.id,response_data['data'].first["id"]
  
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
