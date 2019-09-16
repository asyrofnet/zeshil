class BroadcastReceiptHistory < ActiveRecord::Base
  validates :user_id, presence: true
  validates :broadcast_message_id, presence: true

  belongs_to :user
  belongs_to :broadcast_message

  default_scope { joins(:user)}

  def self.create_history(receiver, broadcast_message_id, sent_at, target)
    if receiver != nil && broadcast_message_id != nil && target != nil
      brh =BroadcastReceiptHistory.find_or_initialize_by(user_id: receiver, broadcast_message_id: broadcast_message_id)
      brh.sent_at = sent_at
      brh.phonenumber = target
      if brh.save!
        return true
      else
        return false
      end
    else
      return false
    end
  end
end