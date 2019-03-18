require 'test_helper'

class API::V1::Posts::CommentsTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user2 attempt to comment with invalid post_id" do
    session2 = auth_sessions(:user2_session2)

    post "/api/v1/posts/20/comments",
      params: {:post_id => 20},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Post not found.', response_data['error']['message']
  end

  test "user2 attempt to comment with empty comment content" do
    session2 = auth_sessions(:user2_session2)
    post1 = posts(:post1)

    post "/api/v1/posts/#{post1.id}/comments",
      params: {:post_id => post1.id},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Comment content cannot be empty.', response_data['error']['message']
  end

  test "user2 attempt to comment with valid post_id and comment content" do
    session2 = auth_sessions(:user2_session2)
    post1 = posts(:post1)
    user2 = users(:user2)

    post "/api/v1/posts/#{post1.id}/comments",
      params: {:post_id => post1.id, :content => 'Comment for Post 2'},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    # Ensure user2 is comment creator
    assert_equal user2.fullname, response_data['data']['comments']['creator']['fullname']
    # Ensure that post1 is commented post
    assert_equal post1.id, response_data['data']['post']['id']
  end

  test "user1 attempt to delete comment with invalid comment_id" do
    session1 = auth_sessions(:user1_session1)
    post1 = posts(:post1)
    user2 = users(:user2)

    delete "/api/v1/posts/#{post1.id}/comments/100",
      params: {:post_id => post1.id, :comment_id => 100},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "Comment not found.", response_data['error']['message']
  end

  test "user2 attempt to delete comment by user1" do
    session2 = auth_sessions(:user2_session2)
    post1 = posts(:post1)
    comment2 = comments(:comment2)

    delete "/api/v1/posts/#{post1.id}/comments/#{comment2.id}",
      params: {:post_id => post1.id, :comment_id => comment2.id},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal "Not post owner or comment owner.", response_data['error']['message']
  end

  test "user2 attempt to delete his own comment" do
    session2 = auth_sessions(:user2_session2)
    post1 = posts(:post1)
    comment1 = comments(:comment1)
    user2 = users(:user2)

    delete "/api/v1/posts/#{post1.id}/comments/#{comment1.id}",
      params: {:post_id => post1.id, :comment_id => comment1.id},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal user2.id, response_data['data']['user_id']
  end
end