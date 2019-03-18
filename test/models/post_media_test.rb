require 'test_helper'

class PostMediaTest < ActiveSupport::TestCase
	setup do
		@post_media = PostMedia.new(
			post_id: 100,
			content_type: 'image/jpeg',
			media_type: 'image',
			sub_type: 'jpeg',
			size: '7053',
			original_filename: 'avatar.jpg',
			compressed_link: 'http://res.cloudinary.com/qiscus/image/upload/q_60/v1/post_media_qisme_user_id_1/ueccavm1gyfzuhfwtcle',
			link: 'http://res.cloudinary.com/qiscus/image/upload/v1494313786/post_media_qisme_user_id_1/ueccavm1gyfzuhfwtcle.jpg'
		)
  	end

  	test "should be valid" do
    	assert @post_media.valid?
  	end

  	test 'content_type should be present' do
    	@post_media.content_type= "         "
    	assert_not @post_media.content_type?
	end

  	test 'media_type should be present' do
    	@post_media.media_type= "         "
    	assert_not @post_media.media_type?
	end

  	test 'sub_type should be present' do
    	@post_media.sub_type= "         "
    	assert_not @post_media.sub_type?
	end

  	test 'size should be present' do
    	@post_media.size = "         "
    	assert_not @post_media.size?
	end

  	test 'original_filename should be present' do
    	@post_media.original_filename = "         "
    	assert_not @post_media.original_filename?
	end

  	test 'compressed_link should be present' do
    	@post_media.compressed_link = "         "
    	assert_not @post_media.compressed_link?
	end

  	test 'link should be present' do
    	@post_media.link = "         "
    	assert_not @post_media.link?
	end

end