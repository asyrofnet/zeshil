class BroadcastReceiptHistory < ActiveRecord::Base
  validates :chat_room_id, presence: true
  validates :user_id, presence: true
  validates :broadcast_message_id, presence: true

  belongs_to :chat_room
  belongs_to :user
  belongs_to :broadcast_message

  default_scope { joins(:user)}

end