class SmsVerificationLog < ActiveRecord::Base
  validates :user_id, presence: true
  validates :provider_id, presence: true

  belongs_to :user
  belongs_to :provider

  default_scope { joins(:user)}

end
