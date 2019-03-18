require 'test_helper'

class PostTest < ActiveSupport::TestCase
	setup do
		@post = Post.new(
			user_id: 100,
			content: 'This is new post',
			post_id: 100,
			is_shared_post: 'FALSE',
			is_public_post: 'TRUE',
		)
  	end

  	test "should be valid" do
    	assert @post.valid?
  	end

  	test 'user_id should be present' do
    	@post.user_id = "         "
    	assert_not @post.user_id?
	end

end