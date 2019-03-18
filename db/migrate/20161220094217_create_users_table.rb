class CreateUsersTable < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :phone_number, null: false
      t.string :passcode, null: true, limit: 6
      t.string :fullname, null: true
      t.string :email, null: true
      t.integer :gender, null: true # will treated as enum in active record model
      t.date :date_of_birth, null: true
      t.string :avatar, null: true
      t.integer :application_id, null: false
      t.boolean :is_public, default: false
      t.integer :verification_attempts, default: 0
      t.string :qiscus_token, null: false
      t.timestamps
    end

    # ALTER TABLE "users" ADD CONSTRAINT fk_rails_cd7919a22b FOREIGN KEY ("application_id") REFERENCES "applications" ("id")
    add_foreign_key :users, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_index :users, [:phone_number, :application_id], unique: true
  end
end
