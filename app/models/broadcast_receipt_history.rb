class BroadcastReceiptHistory < ActiveRecord::Base
  validates :user_id, presence: true
  validates :broadcast_message_id, presence: true

  belongs_to :user
  belongs_to :broadcast_message

  default_scope { joins(:user)}

  def self.create_history(sender, broadcast_message_id, sent_at, target)
    if sender != nil && broadcast_message_id != nil && target != nil
      brh = BroadcastReceiptHistory.new(user_id: sender, broadcast_message_id: broadcast_message_id, sent_at: sent_at, phonenumber: target)
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