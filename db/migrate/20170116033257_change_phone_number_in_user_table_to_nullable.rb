class ChangePhoneNumberInUserTableToNullable < ActiveRecord::Migration[5.0]
  def change
    # Change the column to allow null, this because the requirement has changed
    # previous requirement: only using phone number to login
    # at this point, user can login or register using email
    change_column :users, :phone_number, :string, :null => true
  end
end
