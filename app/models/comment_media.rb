class CommentMedia < ActiveRecord::Base
  # "media" is already plural form
  self.table_name = "comment_media"

  validates :content_type, presence: true
  validates :media_type, presence: true
  validates :sub_type, presence: true
  validates :size, presence: true
  validates :original_filename, presence: true
  validates :compressed_link, presence: true
  validates :link, presence: true

  belongs_to :comment
end
