class Api::V1::Posts::CommentsController < ProtectedController
  before_action :authorize_user
  before_action :media_params, only: [:create]

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/posts/:post_id/comments Get Post Comments
  # @apiDescription Get Post Comments
  # @apiName GetPostComments
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

      per_page = 25

      comments = post.comments.includes(:comment_media, :user).where(comment_id: nil).order(created_at: :asc)
      total_comments = comments.count
      total_page = (total_comments/per_page.to_f).ceil
      total_page = ((total_comments / per_page) <= 0) ? 1 : (total_page)

      # if page is empty then it will display last page
      if params[:page].nil? || params[:page] == ""
        page = total_page
      else
        page = params[:page]
      end

      comments = comments.page(page)

      render json: {
        meta: {
          current_page: page,
          per_page: per_page,
          total_page: total_page,
          total_comments: total_comments
        },
        data: comments
      }
    rescue => e
      render json: {
        error: {
          message: e.message,
          backtrace: e.backtrace
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/posts/:post_id/comments Create New Comments
  # @apiDescription Create Post Comments
  # @apiName CreatePostComments
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} post_id Post id
  # @apiParam {String} content Comment text content. Maximum length of comment is 400 character
  # @apiParam {Array} media[] Comment media, must be an array of file. This is optional.
  # @apiParam {Number} [parent_comment_id=null] Parent comment id.
  # @apiParam {String} [show_media_list_as] You can show media as an object (will return first media), or as an array (will retun array of media).
  # Default is return object. Possible value is `array` or `object`.
  # =end
  def create
    begin
      post = Post.find_by(id: params[:post_id])

      if post.nil?
        raise InputError.new('Post not found.')
      end

      if params[:content].nil? || params[:content] == ""
        raise InputError.new("Comment content cannot be empty.")
      end

      media = []
      comment = Comment.new
      ActiveRecord::Base.transaction do
        comment.user_id = @current_user.id
        comment.post_id = post.id
        comment.content = params[:content]

        # In nested comment, check whether comment parent is really parrent or not.
        # If it is child comment, then raise an error
        if !params[:parent_comment_id].nil? && params[:parent_comment_id] != ""
          parent_comment = Comment.find(params[:parent_comment_id])
          if parent_comment.comment_id.nil?
            comment.comment_id = parent_comment.id
          else
            raise InputError.new("Cannot comment in child comment section.")
          end
        end

        save = comment.save

        raise InputError.new("Comment maximum character is 400.") unless save

        media_params = @media_params
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        # iterate over media params
        media_params.each do | medium |
          # comment media inside transaction
          # this ensure all media successfully saved in another service then save it to db
          url = qiscus_sdk.upload_file(@current_user.qiscus_token, medium)

          # tmp = MimeMagic.by_magic(medium) # caused 'closed stream problem'
          tmp = MimeMagic.by_path(url)
          tmp = JSON.parse(tmp.to_json) # will return hash
          tmp = tmp.merge({ content_type: tmp["type"] })
          tmp = tmp.merge({ media_type: tmp["mediatype"] })
          tmp = tmp.merge({ sub_type: tmp["subtype"] })

          # The single-table inheritance mechanism failed to locate the subclass: 'image/png'.
          # This error is raised because the column 'type' is reserved for storing the class in case of inheritance.
          # Please rename this column if you didn't intend it to be used for storing the inheritance class or overwrite
          # PostMedia.inheritance_column to use another column for that information.
          tmp.delete("type")
          tmp.delete("mediatype")
          tmp.delete("subtype")
          tmp = tmp.merge({ size: medium.size, original_filename: medium.original_filename })

          # 60 compressed
          split_url = url.split("/upload/")
          compressed_link = split_url[0] + "/upload/q_60/" + split_url[1]
          tmp = tmp.merge({ link: url, compressed_link: compressed_link })

          # add comment id
          tmp = tmp.merge({ comment_id: comment.id })
          tmp = tmp.merge({ additional_info: {} }) # since using qiscus uploaderi there is no addtional info

          media.push(tmp)
        end

        # insert comment media
        CommentMedia.create(media)
      end

      post_id = post.id
			post_owner_id = post.user_id
      post_commenter_id = @current_user.id
      user_ids = post.comments.pluck(:user_id) # get all user who was commented
			user_ids = user_ids << post_owner_id
      user_ids = user_ids.uniq
      user_ids -= [post_commenter_id] # no need to send PN to his self

      show_media_list_as = params[:show_media_list_as]
      if show_media_list_as == "array"
        post = post.as_post_list_json
      else
        post = post.as_json
      end

      CommentPushNotificationJob.perform_later(post_id, post_commenter_id, user_ids, show_media_list_as)

      render json: {
        data: {
          post: post,
          comments: comment
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
  # @api {delete} /api/v1/posts/:post_id/comments/:comment_id Delete Own Comment
  # @apiDescription Only Own Comment and Own Post Can Delete Comment
  # @apiName DeleteComment
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} post_id Post id
  # @apiParam {Number} comment_id Comment id
  # =end
  def destroy
    begin
      comment = Comment.find_by(id: params[:id])

      if comment.nil?
        raise InputError.new("Comment not found.")
      elsif comment.post.user_id == @current_user.id || comment.user_id == @current_user.id
        # delete by post owner or comment owner
        comment.delete
      else
        raise InputError.new("Not post owner or comment owner.")
      end

      render json: {
        data: comment
      } and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  private
    def media_params
      if params[:media].present?
        if params[:media].is_a?(Array)
          @media_params = params[:media]
        else
          render json: {
            error: {
              message: 'Media must be an array of file.'
            }
          }, status: 422 and return
        end
      else
        @media_params = []
      end
    end

end