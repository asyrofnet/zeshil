require 'test_helper'

class API::V1::MeTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to change fullname with 4 character" do
    session1 = auth_sessions(:user1_session1)
    new_fullname = "abc"

    qiscus_sdk = mock()
    qiscus_sdk.expects(:update_profile).returns()
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/me/update_profile",
      params: {:user => {:fullname => new_fullname}},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Fullname is too short (minimum is 4 characters).', response_data['error']['message']
  end

  test "user1 attempt to change fullname and success" do
    session1 = auth_sessions(:user1_session1)
    user1 = users(:user1)
    new_fullname = user1.fullname + " Fullname"

    qiscus_sdk = mock()
    qiscus_sdk.expects(:update_profile).returns()
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/me/update_profile",
      params: {:user => {:fullname => new_fullname}},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal new_fullname, response_data['data']['fullname']
  end

  test "user1 attempt to change email with existing email" do
    session1 = auth_sessions(:user1_session1)
    user1 = users(:user1)
    user2 = users(:user2)
    new_fullname = user1.fullname + " Fullname"
    new_email = user2.email # using user2 email as new email

    qiscus_sdk = mock()
    qiscus_sdk.expects(:update_profile).returns()
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/me/update_profile",
      params: {:user => {:fullname => new_fullname, :email=> new_email}},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "Your submitted email already used by another user. Please use another email.", response_data['error']['message']
  end

  test "user1 attempt to change email and success" do
    session1 = auth_sessions(:user1_session1)
    user1 = users(:user1)
    new_fullname = user1.fullname + " Fullname"
    new_email = "new_email@gmail.com"

    qiscus_sdk = mock()
    qiscus_sdk.expects(:update_profile).returns()
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/me/update_profile",
      params: {:user => {:fullname => new_fullname, :email=> new_email}},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal new_fullname, response_data['data']['fullname']
    assert_equal new_email, response_data['data']['email']
  end

  test "user1 attempt to change gender, date_of_birth, is_public, description" do
    session1 = auth_sessions(:user1_session1)
    user1 = users(:user1)
    new_fullname = user1.fullname + " Fullname"
    new_email = "new_email@gmail.com"
    new_gender = "male"
    new_date_of_birth = "2000-12-12"
    new_is_public = true
    new_description = "This is Description"

    qiscus_sdk = mock()
    qiscus_sdk.expects(:update_profile).returns()
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/me/update_profile",
      params: {:user => {:fullname => new_fullname, :email=> new_email, :gender => new_gender, :date_of_birth => new_date_of_birth, :is_public => new_is_public, :description => new_description}},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal new_fullname, response_data['data']['fullname']
    assert_equal new_email, response_data['data']['email']
    assert_equal new_fullname, response_data['data']['fullname']
    assert_equal new_date_of_birth, response_data['data']['date_of_birth']
    assert_equal new_is_public, response_data['data']['is_public']
    assert_equal new_description, response_data['data']['description']

    # Show user profile to ensure that update profile successfully
    get "/api/v1/me/",
      params: {},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal new_fullname, response_data['data']['fullname']
  end
end