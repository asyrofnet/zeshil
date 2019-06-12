require 'test_helper'

class API::V1::AuthNonceTest < ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "attempt to login or register with invalid app_id" do
    application = applications(:qisme)
    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id+"wrong"}}

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Application id is not found.', response_data['error']['message']
  end

  test "attempt to login or register with empty phone_number" do
    application = applications(:qisme)
    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id,:phone_number => ""}},
         headers: {}

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Phone number is empty.', response_data['error']['message']
  end

  test "attempt to login or register with white space phone_number" do
    application = applications(:qisme)
    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id,:phone_number => " "}},
         headers: {}

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Phone number is empty.', response_data['error']['message']
  end

  test "success to login" do
    application = applications(:qisme)
    user = users(:user1)

    SmsVerification.expects(:request)

    qiscus_sdk = mock()
    qiscus_sdk.expects(:login_or_register_rest).returns('qiscus-token')
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id,:phone_number => user.phone_number}},
         headers: {}

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
  end

  test "success to login for user with empty passcode" do
    application = applications(:qisme)
    user = users(:user99)
    code = "9999"
    SmsVerification.expects(:request)
    SmsVerification.expects(:generate_code).returns(code)
    qiscus_sdk = mock()
    qiscus_sdk.expects(:login_or_register_rest).returns('qiscus-token')
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id,:phone_number => user.phone_number}},
         headers: {}

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
    response_data = JSON.parse(response.body)
    assert_equal code, User.find(99).reload.passcode
  end



  test "success to register" do
    application = applications(:qisme)

    qiscus_sdk = mock()
    qiscus_sdk.expects(:login_or_register_rest).returns('qiscus-token')
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    SmsVerification.expects(:request)

    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id,:phone_number => "+6289987654321"}},
         headers: {}

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
  end

  test "success to register with country code" do
    application = applications(:qisme)

    qiscus_sdk = mock()
    qiscus_sdk.expects(:login_or_register_rest).returns('qiscus-token')
    QiscusSdk.expects(:new).returns(qiscus_sdk)

    SmsVerification.expects(:request)

    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id, :country_code => "+62",:phone_number => "+6289987654321"}},
         headers: {}

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Passcode sent. Please verify your account.', response_data['data']['message']
  end

  test "fail to register if role member empty" do
    application = applications(:qisme)
    user = users(:user1)
    Role.expects(:member).returns(nil)
    SmsVerification.expects(:request).never

    QiscusSdk.expects(:new).never

    post "/api/v1/auth_nonce",
         params: {:user=> {:app_id => application.app_id,:phone_number => "+6289987654321"}},
         headers: {}

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Can\'t find user role, please contact admin to seed their database.', response_data['error']['message']
  end

  test "attempt to resend passcode with invalid app_id" do
    application = applications(:qisme)
    user = users(:user1)

    post "/api/v1/auth_nonce/resend_passcode",
         params: {:user=> {:app_id => application.app_id+"wrong"}},
         headers: {}

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Application id is not found.', response_data['error']['message']
  end

  test "attempt to resend passcode with invalid phone_number" do
    application = applications(:qisme)
    user = users(:user1)

    post "/api/v1/auth_nonce/resend_passcode",
         params: {:user=> {:app_id => application.app_id,:phone_number => user.phone_number+"0"}},
         headers: {}

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Can\'t find user.', response_data['error']['message']
  end

  test "success to resend passcode" do
    application = applications(:qisme)
    user = users(:user1)

    SmsVerification.expects(:request)

    post "/api/v1/auth_nonce/resend_passcode",
         params: {:user=> {:app_id => application.app_id,:phone_number => user.phone_number}},
         headers: {}

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
  end

  test "attempt to verify with invalid app_id" do
    application = applications(:qisme)
    user = users(:user1)

    post "/api/v1/auth_nonce/verify",
         params: {:user=> {:app_id => application.app_id+"wrong"}},
         headers: {}

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Application id is not found.', response_data['error']['message']
  end

  test "attemp to verify with invalid phone number" do
    application = applications(:qisme)
    user = users(:user1)

    post "/api/v1/auth_nonce/verify",
         params: {:user=> {:app_id => application.app_id, :phone_number => user.phone_number+"009", :passcode => user.passcode, :nonce => 'random-string'}},
         headers: {}

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Can\'t find user or wrong passcode.', response_data['error']['message']
  end

  test "attempt to verify with invalid passcode" do
    application = applications(:qisme)
    user = users(:user1)

    post "/api/v1/auth_nonce/verify",
         params: {:user=> {:app_id => application.app_id, :phone_number => user.phone_number, :passcode => '9999', :nonce => 'random-string'}},
         headers: {}

    assert_equal 404, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Can\'t find user or wrong passcode.', response_data['error']['message']
  end

  test "attempt to verify with empty passcode" do
    application = applications(:qisme)
    user = users(:user1)

    post "/api/v1/auth_nonce/verify",
         params: {:user=> {:app_id => application.app_id, :phone_number => user.phone_number, :passcode => '', :nonce => 'random-string'}},
         headers: {}

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'passcode cannot be empty.', response_data['error']['message']
  end

  test "attempt to verify with empty nonce" do
    application = applications(:qisme)
    user = users(:user1)

    post "/api/v1/auth_nonce/verify",
         params: {:user=> {:app_id => application.app_id, :phone_number => user.phone_number, :passcode => '12345', :nonce => ''}},
         headers: {}

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'nonce cannot be empty.', response_data['error']['message']
  end

  test "success to verify user with valid passcode" do
    application = applications(:qisme)
    user = users(:user1)

    ApplicationHelper.expects(:create_jwt_token)

    post "/api/v1/auth_nonce/verify",
      params: {:user=> {:app_id => application.app_id, :phone_number => user.phone_number, :passcode => user.passcode, :nonce => 'random-string'}},
         headers: {}

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type
  end
end
