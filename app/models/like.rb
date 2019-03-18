class Like < ActiveRecord::Base

  validates :user_id, presence: true
  validates :post_id, presence: true

  belongs_to :user
  belongs_to :post

  default_scope { joins(:user)}

  def as_json(options = {})
    h = super()

    h[:creator] = user.as_json
    
    return h
  end

end