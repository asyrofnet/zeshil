class CreateUserRolesTable < ActiveRecord::Migration[5.0]
  def change
    create_table :user_roles do |t|
      t.integer :user_id
      t.integer :role_id
      t.timestamps
    end

    add_foreign_key :user_roles, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_roles, :roles, column: :role_id, primary_key: :id, on_delete: :cascade, on_update: :cascade

  end
end
