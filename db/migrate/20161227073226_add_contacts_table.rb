class AddContactsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts do |t|
      t.integer :user_id
      t.integer :contact_id
      t.timestamps
    end

    add_foreign_key :contacts, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :contacts, :users, column: :contact_id, primary_key: :id, on_delete: :cascade, on_update: :cascade

    add_index :contacts, [:user_id, :contact_id], unique: true
  end
end
