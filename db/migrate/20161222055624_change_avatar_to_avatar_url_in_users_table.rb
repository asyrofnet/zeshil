class ChangeAvatarToAvatarUrlInUsersTable < ActiveRecord::Migration[5.0]
  def change
    rename_column :users, :avatar, :avatar_url
  end
end
