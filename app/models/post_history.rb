class PostHistory < ActiveRecord::Base
  # "history" is already plural form
  self.table_name = "post_history"

  validates :user_id, presence: true
  validates :post_id, presence: true

  belongs_to :post
  belongs_to :user

  default_scope { joins(:user)}
  
  def as_json(options = {})
    h = super(
      :except => [:post_id, :user_id],
      )
    h[:creator] = user.as_json

    return h
  end
end