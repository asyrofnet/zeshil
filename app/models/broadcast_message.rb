class BroadcastMessage < ActiveRecord::Base
  validates :message, presence: true
  validates :user_id, presence: true
  validates :application_id, presence: true

  belongs_to :application
  belongs_to :user
  has_many :broadcast_receipt_histories

  default_scope { joins(:user)}

end