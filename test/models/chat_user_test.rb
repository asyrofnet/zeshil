require 'test_helper'

class ChatUserTest < ActiveSupport::TestCase
	setup do
		@chat_user = ChatUser.new(
			user_id: '100',
			chat_room_id: '100',
		)
  	end

  	test "should be valid" do
    	assert @chat_user.valid?
  	end

  	test 'user_id should be present' do
    	@chat_user.user_id = "         "
    	assert_not @chat_user.user_id?
	end

	test 'chat_room_id should be present' do
    	@chat_user.chat_room_id = "         "
    	assert_not @chat_user.chat_room_id?
	end

end