class AuthSession < ActiveRecord::Base
  validates :user_id, presence: true
  validates :jwt_token, presence: true

  belongs_to :user

  default_scope { joins(:user)}

  def as_json(options = {})
    h = super({
      :except => [:jwt_token, :user_id]
    })

    return h
  end

end
