class ChangePhoneNumberAndEmailUniquenessInUsersTable < ActiveRecord::Migration[5.0]
  def change
    # remove pair of index before creating new index of such column
    remove_index :users, [:phone_number, :application_id]

    add_index :users, [:phone_number, :email, :application_id], unique: true
  end
end
