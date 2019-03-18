class PostMedia < ActiveRecord::Base
  # "media" is already plural form
  self.table_name = "post_media"

  validates :content_type, presence: true
  validates :media_type, presence: true
  validates :sub_type, presence: true
  validates :size, presence: true
  validates :original_filename, presence: true
  validates :compressed_link, presence: true
  validates :link, presence: true

  belongs_to :post
  
  def as_json(options={})
    h = super()
    h["created_at"] = created_at.iso8601.to_s if options.has_key?(:job)
    h["updated_at"] = updated_at.iso8601.to_s if options.has_key?(:job)
    return h
  end

end
