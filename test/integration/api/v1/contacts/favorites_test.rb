require 'test_helper'

class API::V1::Contacts::FavoritesTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to add contact with invalid user_id" do
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/favorites",
      params: {:user_id=> 5},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'User is not found.', response_data['error']['message']
  end

  test "user1 attempt to add contact with user_id that not in his contact" do
    user3 = users(:user3)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/favorites",
      params: {:user_id=> user3.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'This user is not in your contact. Please add before mark it as favourites.', response_data['error']['message']
  end

  test "user1 attempt to add user2 as a favorite contact" do
    user2 = users(:user2)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/favorites",
      params: {:user_id=> user2.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    # Ensure that user1 success to add user2 as a favorite contact
    get "/api/v1/contacts/favorites",
      params: {},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user2.fullname, response_data['data'][0]['fullname']
  end

  test "user1 attempt to remove favorite contact with invalid id_user" do
    session1 = auth_sessions(:user1_session1)

    delete "/api/v1/contacts/favorites/5",
      params: {:id=> 5},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "User is not found.", response_data['error']['message']
  end

  test "user1 attempt to remove favorite contact with id_user that not in his contact" do
    session1 = auth_sessions(:user1_session1)
    user3 = users(:user3)

    delete "/api/v1/contacts/favorites/#{user3.id}",
      params: {:id=> user3.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "This user is not in your contact. Please add before mark it as favourites.", response_data['error']['message']
  end

  test "user1 attempt to remove user2 as a favorite contact" do
    # First, user1 add user2 as a fovorite contact
    user2 = users(:user2)
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/contacts/favorites",
      params: {:user_id=> user2.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    # Then user1 remove user2
    delete "/api/v1/contacts/favorites/#{user2.id}",
      params: {:id=> user2.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
  end

end