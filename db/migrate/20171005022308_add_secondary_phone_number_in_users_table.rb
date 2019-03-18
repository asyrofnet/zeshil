class AddSecondaryPhoneNumberInUsersTable < ActiveRecord::Migration[5.1]
  def change
		add_column :users, :secondary_phone_number, :string, null: true, default: ""
  end
end
