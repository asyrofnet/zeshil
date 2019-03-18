class ChangeIsAutoFriendDefaultValueInApplicationTable < ActiveRecord::Migration[5.1]
  def change
    change_column :applications, :is_auto_friend, :boolean, default: false
  end
end
