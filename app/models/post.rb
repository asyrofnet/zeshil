class Post < ActiveRecord::Base
  validates :user_id, presence: true

  belongs_to :user
  has_many :post_media, class_name: "PostMedia"
  has_many :comments
  belongs_to :post
  has_many :likes
  has_many :post_history, class_name: "PostHistory"

  default_scope { joins(:user)}

  def as_json(options = {})
    h = super()

    h[:post_media] = (post_media == []) ? {} : post_media.first.as_json
    h[:shared_post] = post.as_json
    h[:creator] = user.as_json
    h[:shared_count] = Post.where(post_id: id).count
    h[:comment_count] = comments.where(comment_id: nil).count
    h[:like_count] = likes.count
    # hide comments object in post, to avoid n+1 query in rails object
    # h[:comments] = comments.as_json
    if options.has_key?(:job)
      h["created_at"] = created_at.iso8601.to_s
      h["updated_at"] = updated_at.iso8601.to_s
      h[:creator] = user.as_json(job: true)
      h[:post_media] = (post_media == []) ? {} : post_media.first.as_json(job: true)
      h[:shared_post] = post.as_json(job: true)
    end
    return h
  end

  # this for show all media as an array
  def as_post_list_json(options = {})
    h = as_json # this is method from this class
    h = as_json(job: true) if options.has_key?(:job)

    h[:post_media] = (post_media == nil) ? [] : post_media.as_json
    h[:shared_post] = (post == nil) ? nil : post.as_post_list_json
    h[:creator] = user.as_json
    h[:shared_count] = Post.where(post_id: id).count
    h[:comment_count] = comments.where(comment_id: nil).count
    h[:like_count] = likes.count
    # hide comments object in post, to avoid n+1 query in rails object
    # h[:comments] = comments.as_json
    if options.has_key?(:job)
      h["created_at"] = created_at.iso8601.to_s
      h["updated_at"] = updated_at.iso8601.to_s
      h[:creator] = user.as_json(job: true)
      h[:post_media] = (post_media == []) ? {} : post_media.as_json(job: true)
      h[:shared_post] = (post == nil) ? nil : post.as_post_list_json(job: true)
    end
    return h
  end
end
