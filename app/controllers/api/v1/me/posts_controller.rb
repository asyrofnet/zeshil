class Api::V1::Me::PostsController < ProtectedController
  before_action :authorize_user
  before_action :media_params, only: [:create]

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/me/posts Get Own Posts
  # @apiDescription Get Own Post
  # @apiName Get Own Post
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} [page=1] Pagination. Per page is 25 record.
  # @apiParam {String} [show_media_list_as] You can show media as an object (will return first media), or as an array (will retun array of media).
  # Default is return object. Possible value is `array` or `object`.
  # =end
  def index
    total_posts = Post.where(user_id: @current_user.id).count
    posts = Post.where(user_id: @current_user.id).order(created_at: :desc).page(params[:page])

    show_media_list_as = params[:show_media_list_as]
    if show_media_list_as == "array"
      posts = posts.map do | post |
        post.as_post_list_json
      end
    else
      posts = posts.as_json
    end

    posts = posts.map do |e|
      liked_post = Like.find_by(user_id: @current_user.id, post_id: e["id"])

      # default value is_liked_post = false
      is_liked_post = false

      is_liked_post = true unless liked_post.nil?
      e.merge!('is_liked_post' => is_liked_post )
    end


    render json: {
      meta: {
        current_page: (params[:page].to_i <= 0) ? 1 : params[:page].to_i,
        per_page: 25,
        total_page: ((total_posts / 25) <= 0 ) ? 1 : (total_posts / 25),
        total_posts: total_posts
      },
      data: posts
    }
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/me/posts/:post_id Delete Own Post
  # @apiDescription Delete Own Post
  # @apiName DeleteOwnPost
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} post_id Post id
  # @apiParam {String} [show_media_list_as] You can show media as an object (will return first media), or as an array (will retun array of media).
  # =end
  def destroy
    begin
      post = Post.where(user_id: @current_user.id).where(id: params[:id]).first

      if post.nil?
        raise InputError.new("Post not found")
      end

      post.delete

      show_media_list_as = params[:show_media_list_as]
      if show_media_list_as == "array"
        post = post.as_post_list_json
      else
        post = post.as_json
      end

      render json: {
        data: post
      } and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end