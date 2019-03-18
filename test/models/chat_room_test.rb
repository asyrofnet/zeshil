require 'test_helper'

class ChatRoomTest < ActiveSupport::TestCase
	setup do
		@chat_room = ChatRoom.new(
			qiscus_room_name: 'qiscus-room-name-1',
			qiscus_room_id: '100',
			is_group_chat: 'false',
			user_id: '3',
			group_chat_name: 'Single Chat Name',
			application_id: '1',
			group_avatar_url: 'https://res.cloudinary.com/qiscus/image/upload/NITXR7pLhz/avatar.jpg',
			is_official_chat: 'false',
			target_user_id: '4'
		)
  	end

  	test "should be valid" do
    	assert @chat_room.valid?
  	end

  	test 'qiscus_room_name should be present' do
    	@chat_room.qiscus_room_name = "         "
    	assert_not @chat_room.qiscus_room_name?
	end

	test 'qiscus_room_id should be present' do
    	@chat_room.qiscus_room_id = "         "
    	assert_not @chat_room.qiscus_room_id?
	end

	test 'user_id should be present' do
    	@chat_room.user_id = "         "
    	assert_not @chat_room.user_id?
	end

	test 'application_id should be present' do
    	@chat_room.application_id = "         "
    	assert_not @chat_room.application_id?
	end

	test 'target_user_id should be present' do
    	@chat_room.target_user_id = "         "
    	assert_not @chat_room.target_user_id?
	end

end