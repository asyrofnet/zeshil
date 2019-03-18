class UserFeature < ActiveRecord::Base
  belongs_to :user
  belongs_to :feature

  default_scope { joins(:user)}

end