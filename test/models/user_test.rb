require 'test_helper'

class UserTest < ActiveSupport::TestCase
	setup do
		@user = User.new(
			phone_number: '+6285123456789',
			fullname: 'User 1',
			email: 'user1@gmail.com',
			gender: 'male',
			date_of_birth: '1990-01-01',
			avatar_url: 'https://res.cloudinary.com/qiscus/image/upload/NITXR7pLhz/avatar.jpg',
			application_id: '1',
			is_public: 'false',
			verification_attempts: '0',
			qiscus_token: 'IaF7RqdC5xj96lfO8umL',
			qiscus_email: 'userid_1_6285123456789@dummy.com',
			description: 'Hello World!',
			callback_url: '',
		)
  	end

  	test "should be valid" do
    	assert @user.valid?
  	end

	test 'qiscus_email should be present' do
    	@user.qiscus_email = "         "
    	assert_not @user.qiscus_email?
	end

end