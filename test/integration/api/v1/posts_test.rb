require 'test_helper'

class API::V1::PostsTest< ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test "user1 attempt to share a new post with empty post content and media" do
    session1 = auth_sessions(:user1_session1)

    post "/api/v1/posts",
      params: {},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    assert_equal 'Post content or media cannot be empty.', response_data['error']['message']
  end

  test "user1 attempt to share a new post with empty media" do
    session1 = auth_sessions(:user1_session1)
    user1 = users(:user1)

    post "/api/v1/posts",
      params: {:content => 'Post Content'},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    # Ensure user1 is post creator
    assert_equal user1.fullname, response_data['data']['creator']['fullname']
  end

  test "user2 attempt to delete user1 post" do
    session2 = auth_sessions(:user2_session2)
    post1 = posts(:post1)

    delete "/api/v1/posts/#{post1.id}",
      params: {:post_id=> post1.id},
      headers: { 'Authorization' => token_header(session2.jwt_token) }

    assert_equal 422, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    # Post not found because user2 cannot delete user1 post
    assert_equal 'Post not found', response_data['error']['message']
  end

  test "user1 attempt to delete post1" do
    session1 = auth_sessions(:user1_session1)
    post1 = posts(:post1)

    delete "/api/v1/posts/#{post1.id}",
      params: {:post_id=> post1.id},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    # User 1 success to donwload post1
    assert_equal post1.content, response_data['data']['content']
  end

  test "user3 attempt to get post list" do
    session3 = auth_sessions(:user3_session3)

    get "/api/v1/posts",
      params: {},
      headers: { 'Authorization' => token_header(session3.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    # User3 contact is empty, so user3 cant get post list
    assert_equal [], response_data['data']
  end

  test "user1 attempt to get post list" do
    session1 = auth_sessions(:user1_session1)
    post1 = posts(:post1)
    post2 = posts(:post2)

    get "/api/v1/posts",
      params: {},
      headers: { 'Authorization' => token_header(session1.jwt_token) }

    assert_equal 200, response.status
    assert_equal Mime[:json], response.content_type

    response_data = JSON.parse(response.body)
    # User1 only friend with user2
    assert_equal post1.id, response_data['data'][0]['id']
    assert_equal post2.id, response_data['data'][1]['id']
  end

end