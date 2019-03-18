class UserDedicatedPasscode < ActiveRecord::Base
  validates :passcode, presence: true, length: { is: 4 }
  validates :user_id, presence: true
  validates :application_id, presence: true

  belongs_to :application
  belongs_to :user

  default_scope { joins(:user)}

end