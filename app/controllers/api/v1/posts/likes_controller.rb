class Api::V1::Posts::LikesController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/posts/:post_id/likes Get Post Likes
  # @apiDescription Get Post Likes
  # @apiName GetPostLikes
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} post_id Post id
  # @apiParam {Number} [page=1] Pagination. Per page is 25 record.
  # =end
  def index
    begin
      post = Post.find(params[:post_id])

      if post.nil?
        raise InputError.new('Post not found.')
      end

      likes = post.likes.order(created_at: :asc)
      total_likes = likes.count
      likes = likes.page(params[:page])

      render json: {
        meta: {
          current_page: (params[:page].to_i <= 0) ? 1 : params[:page].to_i,
          per_page: 25,
          total_page: ((total_likes / 25) <= 0 ) ? 1 : (total_likes / 25),
          total_likes: total_likes 
        },
        data: likes
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/posts/:post_id/likes Like Post
  # @apiDescription Like Post
  # @apiName LikePost
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} [show_media_list_as] You can show media as an object (will return first media), or as an array (will retun array of media).
  # Default is return object. Possible value is `array` or `object`.
  # =end
  def create
    begin
      show_media_list_as = params[:show_media_list_as]

      post = Post.find_by(id: params[:post_id])

      if post.nil?
        raise InputError.new('Post not found.')
      end

      like = Like.find_by(user_id: @current_user.id, post_id: params[:post_id])

      if !like.nil?
        raise InputError.new('You are already like this post.')
      end

      like = Like.new
      ActiveRecord::Base.transaction do
        like.user_id = @current_user.id
        like.post_id = post.id
        like.save

        post_id = post.id
        post_owner_id = post.user_id
        post_liker_id = @current_user.id

        # send PN to post owner
        if post_owner_id != post_liker_id # no need to send PN when user like his own post
          LikePushNotificationJob.perform_later(post_id, post_owner_id, post_liker_id, show_media_list_as)
        end
      end

      if show_media_list_as == "array"
        post = post.as_post_list_json
      else
        post = post.as_json
      end

      render json: {
        data: {
          post: post,
          likes: like
        }

      }, status: 200 and return
    
    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/me/posts/:post_id/likes Unlike Post
  # @apiDescription Unlike post
  # @apiName UnlikePost
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # =end
  def destroy
    begin
      like = Like.find_by(post_id: params[:post_id], user_id: @current_user.id)

      if like.nil?
        raise InputError.new("You have not like this post yet.")
      end
      
      like.delete
      
      render json: {
        data: like
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