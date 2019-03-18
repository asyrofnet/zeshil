class Comment < ActiveRecord::Base

  validates :user_id, presence: true
  validates :post_id, presence: true
  validates :content, presence: true, length: { maximum: 400}

  has_one :comment_media, class_name: "CommentMedia"
  belongs_to :user
  belongs_to :comment
  belongs_to :post

  default_scope { joins(:user)}

  def as_json(options = {})
    h = super()

    h[:comment_media] = (comment_media == nil) ? {} : comment_media
    h[:creator] = user.as_json
    h[:comments] = Comment.where(comment_id: id).order(created_at: :desc).as_json
    
    return h
  end
end