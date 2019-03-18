require 'test_helper'

class API::V1::ContactsTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to add contact with user1 id" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts",
      params: {:contact_id=> user1.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'You can not add your self as contact.', response_data['error']['message']
  end

  test "user1 attempt to add user2, already on his contact" do
    user1 = users(:user1)
    user2 = users(:user2)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts",
      params: {:contact_id=> user2.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'User already in your contact.', response_data['error']['message']
  end

  test "user1 attempt to add contact without contact id" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts",
      params: {:contact_id=> ""},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Contact id must be present.', response_data['error']['message']
  end

  test "user1 attempt to add not known user" do
    user1 = users(:user1)
    user4 = users(:user4) # there is no user4
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts",
      params: {:contact_id=> user4.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Contact id is not found.', response_data['error']['message']
  end

  test "user1 attempt to add user3, success" do
    user1 = users(:user1)
    user3 = users(:user3)
    session1 = auth_sessions(:user1_session1)
    session3 = auth_sessions(:user3_session3)

    post "/api/v1/contacts",
      params: {:contact_id=> user3.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    # User3 get contact list to ensure that user1 in his contact
    get "/api/v1/contacts",
      params: {:exclude=> 'official'},
      headers: { 'Authorization' => token_header(session3.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user1.id, response_data['data'][0]['id']
  end

  # test to delete user
  test "user1 attempt to delete user with empty string" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)

    delete "/api/v1/contacts/delete_contact",
      params: {:contact_id=> ""},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Contact id can not be empty string.', response_data['error']['message']
  end

  test "user1 attempt to delete user2" do
    user1 = users(:user1)
    user2 = users(:user2)
    session1 = auth_sessions(:user1_session1)
    session2 = auth_sessions(:user2_session2)

    delete "/api/v1/contacts/delete_contact",
      params: {:contact_id=> user2.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user2.id, response_data['data']['id']
  end

  # test to search user
  test "user1 attempt to search user3 with invalid phone number" do
    user1 = users(:user1)
    user3 = users(:user3)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search",
      params: {:phone_number=> user3.phone_number.chomp("2345")},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "User not found.", response_data['error']['message']
  end

  test "user1 attempt to search user2 with valid but already in his contact" do
    user1 = users(:user1)
    user2 = users(:user2)
    session1 = auth_sessions(:user1_session1)
    session2 = auth_sessions(:user2_session2)

    post "/api/v1/contacts/search",
      params: {:phone_number=> user2.phone_number},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "User already in your contact.", response_data['error']['message']
  end

  test "user1 attempt to search user with invalid minimum phone number" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search",
      params: {:phone_number=> "12345"},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "Minimum phone number is 9", response_data['error']['message']
  end

  test "user1 attempt to search user3 with valid phone number" do
    user1 = users(:user1)
    user3 = users(:user3)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search",
      params: {:phone_number=> user3.phone_number},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user3.id, response_data['data']['id']
  end

  # test search by qiscus_email
  test "user1 attempt to search user with empty qiscus email" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search_by_qiscus_email",
      params: {:qiscus_email=> ""},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "Qiscus email can't be empty.", response_data['error']['message']
  end

  test "user1 attempt to search unknown user" do
    user1 = users(:user1)
    user4 = users(:user4)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search_by_qiscus_email",
      params: {:qiscus_email=> user4.qiscus_email},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "User not found.", response_data['error']['message']
  end

  test "user1 attempt to search user3 with valid qiscus email" do
    user1 = users(:user1)
    user3 = users(:user3)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search_by_qiscus_email",
      params: {:qiscus_email=> user3.qiscus_email},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user3.qiscus_email, response_data['data']['qiscus_email']
  end

  # test search by email
  test "user1 attempt to search user with empty email" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search_by_email",
      params: {:email=> ""},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "Email can't be empty.", response_data['error']['message']
  end

  test "user1 attempt to search unknown user with email" do
    user1 = users(:user1)
    user4 = users(:user4)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search_by_email",
      params: {:email=> user4.email},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "User not found.", response_data['error']['message']
  end

  test "user1 attempt to search user3 with valid email" do
    user1 = users(:user1)
    user3 = users(:user3)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/search_by_email",
      params: {:email=> user3.email},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user3.email, response_data['data']['email']
  end

  # search by all field
  test "user1 attempt to search user2 with valid query" do
    user1 = users(:user1)
    user2 = users(:user2)
    session1 = auth_sessions(:user1_session1)
    query = "+6285643123456 Setiawan setiawan@gmail.com userid_2_6285643123456@qisme.com"

    post "/api/v1/contacts/search_by_all_field",
      params: {:query=> query},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user2.fullname, response_data['data'][0]['fullname']
  end

  test "user1 attempt to search user2 with using not-complete fullname, email, qiscus_email, and phone_number" do
    user1 = users(:user1)
    user2 = users(:user2)
    session1 = auth_sessions(:user1_session1)
    query = "+6285643123 Setia"

    post "/api/v1/contacts/search_by_all_field",
      params: {:query=> query},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user2.fullname, response_data['data'][0]['fullname']
  end

  test "user1 attempt to search without query" do
    user1 = users(:user1)
    session1 = auth_sessions(:user1_session1)
    user_count = User.where.not(id: user1.id).where(application_id: user1.application_id).count

    post "/api/v1/contacts/search_by_all_field",
      params: {:query=> nil},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user_count, response_data['meta']['total']
  end

end