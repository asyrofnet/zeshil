class UserDeviceToken < ActiveRecord::Base
  validates :devicetoken, presence: true, :uniqueness => {:case_sensitive => false}
  validates :user_type, presence: true
  validates :user_id, presence: true

  belongs_to :user

  default_scope { joins(:user)}

  def as_json(options = {})
    h = super(
      :except => [:user_id]
    )

    return h
  end

end
