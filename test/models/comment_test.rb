require 'test_helper'

class CommentTest < ActiveSupport::TestCase
	setup do
		@comment = Comment.new(
			user_id: 100,
			post_id: 100,
			content: 'This is a comment',
		)
  	end

  	test "should be valid" do
    	assert @comment.valid?
  	end

  	test 'user_id should be present' do
    	@comment.user_id = "         "
    	assert_not @comment.user_id?
	end

  	test 'post_id should be present' do
    	@comment.post_id = "         "
    	assert_not @comment.comment_id?
	end


  	test 'comment should be present' do
    	@comment.content = "         "
    	assert_not @comment.content?
	end

end