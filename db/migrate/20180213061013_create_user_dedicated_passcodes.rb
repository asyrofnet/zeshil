class CreateUserDedicatedPasscodes < ActiveRecord::Migration[5.1]
  def change
    create_table :user_dedicated_passcodes do |t|
      t.string :passcode, null: true
      t.integer :user_id, null: false
      t.integer :application_id, null: false
      t.timestamps
    end

    add_foreign_key :user_dedicated_passcodes, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_dedicated_passcodes, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
