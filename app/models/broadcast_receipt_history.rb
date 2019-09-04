class BroadcastReceiptHistory < ActiveRecord::Base
  validates :user_id, presence: true
  validates :broadcast_message_id, presence: true

  belongs_to :user
  belongs_to :broadcast_message

  default_scope { joins(:user)}

  def self.create_history(user_id, broadcast_message_id, sent_at)
    if user_id != nil && broadcast_message_id != nil
      brh = BroadcastReceiptHistory.new(user_id: user_id, broadcast_message_id: broadcast_message_id, sent_at: sent_at)
      if brh.save!
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def self.get_history(user_id)
    if user_id != nil
      history = BroadcastReceiptHistory.select('broadcast_message_id').where('user_id = ?', user_id).distinct
      return history
    else
      return false
    end
  end
end