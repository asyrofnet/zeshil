class Api::V1::PostsController < ProtectedController
  before_action :authorize_user
  before_action :media_params, only: [:create]

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/posts Get Posts
  # @apiDescription Get Post
  # @apiName GetPost
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} [page=1] Pagination. Per page is 25 record.
  # @apiParam {String} [show_media_list_as] You can show media as an object (will return first media), or as an array (will retun array of media).
  # Default is return object. Possible value is `array` or `object`.
  # =end
  def index
    # get post from user contact, own self and official account
    user_ids = @current_user.contacts.pluck(:contact_id).to_a + [@current_user.id]

    # official account inclusion
    role_official_user = Role.official
    user_role_ids = UserRole.where(role_id: role_official_user.id).pluck(:user_id).to_a
    official_account = User.where("id IN (?)", user_role_ids).where(application_id: @current_user.application_id)
    official_account = official_account.where.not(id: @current_user.id)
    official_account = official_account.pluck(:id)

		user_ids = user_ids + official_account
    user_ids = user_ids.uniq{|item| item}

    total_posts = Post.where("posts.user_id IN (?)", user_ids).count
    posts = Post.where("posts.user_id IN (?)", user_ids).order(created_at: :desc).page(params[:page])

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
  # @api {post} /api/v1/posts Create or Share A Post
  # @apiDescription Create post or sharing a post
  # @apiName CreateOrSharePost
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} content Post text content
  # @apiParam {Array} media[] Post media, must be an array of file. This is optional.
  # @apiParam {Number} [share_post_id=null] Post to share. This is optional.
  # @apiParam {String} [link=null] Url media to share or included in post media. This is optional.
  # @apiParam {String} [link_meta=null] Link meta should contain pre-fetch data such as title or caption. This must be valid JSON string, otherwise will return error
  # @apiParam {String} [show_media_list_as] You can show media as an object (will return first media), or as an array (will retun array of media).
  # Default is return object. Possible value is `array` or `object`.
  # =end
  def create
    begin
      media = []
      post = Post.new
      post.user_id = @current_user.id

      # if user share a post than the content and media can be empty
      if !params[:share_post_id].present? || params[:share_post_id].nil?
        # if user create a new post then content or media cannot be empty
        if !params[:content].present? && @media_params.empty?
          raise StandardError.new("Post content or media cannot be empty.")
        end
      end

      ActiveRecord::Base.transaction do
        # create post
        post.content = params[:content]

        # In sharing mode, we must check whether the post that will be share is parent post or not.
        # To check it, look if post_id on that post is null (if null = parent, if not null = shared post).
        # If not parent post, then post_id is marked as post_id to shared post.
        # This to avoid recursive shared post.
        if !params[:share_post_id].nil? && params[:share_post_id] != ""
          shared_post = Post.find(params[:share_post_id])
          if shared_post.post_id.nil?
            post.post_id = shared_post.id
          else
            post.post_id = shared_post.post_id
          end

          post.is_shared_post = true
          post.share_referrer_id = shared_post.user_id
        end

        post.save

        media_params = @media_params
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        # iterate over media params
        media_params.each do | medium |
          # post media inside transaction
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
          # split url
          split_url = url.split("/upload/")
          compressed_link = split_url[0] + "/upload/q_60/" + split_url[1]
          tmp = tmp.merge({ link: url, compressed_link: compressed_link })

          # add post id
          tmp = tmp.merge({ post_id: post.id })
          tmp = tmp.merge({ additional_info: {} }) # since using qiscus uploaderi there is no addtional info

          media.push(tmp)
        end

        # add link media to post media
        if params[:link] != "" && params[:link].present?
          link_meta = {}
          if params[:link_meta].present?
            if params[:link_meta].is_a?(String)
              begin
                link_meta = JSON.parse(params[:link_meta])
              rescue => e
                raise StandardError.new('Link meta params is malformed JSON string.')
              end
            else
              raise StandardError.new('Link meta params must be string.')
            end
          end

          link_media = {
            content_type: 'text/plain',
            media_type: 'url',
            sub_type: 'http',
            size: params[:link].size,
            original_filename: params[:link],
            compressed_link: params[:link],
            link: params[:link],
            post_id: post.id,
            additional_info: link_meta
          }

          media.push(link_media)
        end

        # add post media
        PostMedia.create(media)
      end

      if params[:show_media_list_as] == "array"
        post = post.as_post_list_json
      end

      render json: {
        data: post
      }
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
  # @api {delete} /api/v1/posts/:post_id Delete Posts
  # @apiDescription Delete Post, only post owner can delete a post. This is alias for delete `/api/v1/me/post/:post_id `
  # @apiName DeletePost
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
        raise StandardError.new("Post not found")
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

  # =begin
  # @apiVersion 1.0.0
  # @api {patch} /api/v1/posts/:post_id Update Post
  # @apiDescription Update Post
  # @apiName UpdatePost
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} content New content
  # @apiParam {String} [show_media_list_as] You can show media as an object (will return first media), or as an array (will retun array of media).
  # =end
  def update
    begin
      if !params[:content].present? || params[:content] == ""
        raise StandardError.new("Post content cannot be empty.")
      end

      post = Post.find(params[:id])
      if post.nil?
        raise StandardError.new("Post not found.")
      end

      # only post owner that can update post
      if post.user_id != @current_user.id
        raise StandardError.new("Only post owner that can update post.")
      end

      ActiveRecord::Base.transaction do
        # only update when old content and new content is different
        if params[:content] != post.content
          # update post
          old_content = post.content # get old content and then save it to post_history table

          post.content = params[:content]
          post.is_updated_post = true
          post.save!

          # save old_content to
          post_history = PostHistory.new
          post_history.user_id = @current_user.id
          post_history.content = old_content
          post_history.post_id = post.id
          post_history.save!
        end
      end

      show_media_list_as = params[:show_media_list_as]
      if show_media_list_as == "array"
        post = post.as_post_list_json
      else
        post = post.as_json
      end

      render json: {
        data: post
      }
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
  # @api {get} /api/v1/posts/:post_id Get Updated Post History
  # @apiDescription Get Updated Post History
  # @apiName GetUpdatedPostHistory
  # @apiGroup Post
  #
  # @apiParam {String} access_token User access token
  # =end
  def show
    begin
      post = Post.find(params[:id])

      if post.nil?
        raise StandardError.new('Post not found.')
      end

      post_history = post.post_history.order(created_at: :desc)

      render json: {
        data: post_history
      }
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