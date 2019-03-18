require 'test_helper'

class ApplicationTest < ActiveSupport::TestCase
	setup do
		@application = Application.new(
			app_id: 'dummy',
			app_name: 'Dummy Application',
			description: 'Description Dummy Application',
			qiscus_sdk_url: 'http://dummy.qiscus.com',
			qiscus_sdk_secret: 'dummy-123',
		)
  	end

  	test "should be valid" do
    	assert @application.valid?
  	end

	test 'app_id should be present' do
    	@application.app_id = "         "
    	assert_not @application.app_id?
	end

	test 'app_name should be present' do
    	@application.app_name = "         "
    	assert_not @application.app_name?
	end

	test 'qiscus_sdk_url should be present' do
    	@application.qiscus_sdk_url = "         "
    	assert_not @application.qiscus_sdk_url?
	end

	test 'qiscus_sdk_secret should be present' do
    	@application.qiscus_sdk_secret = "         "
    	assert_not @application.qiscus_sdk_secret?
	end

	test "app_id should be unique" do
    	duplicate_application = @application.dup
    	duplicate_application.app_id = @application.app_id.upcase
    	@application.save
    	assert_not duplicate_application.valid?
  	end

end