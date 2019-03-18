class CreateUserTokensTable < ActiveRecord::Migration[5.1]
  def change
    create_table :user_tokens do |t|
  	  t.string :token
	    t.string :app_type
      t.boolean :is_active, default: true
      t.integer :user_id, null: false
      t.timestamps
    end

    add_foreign_key :user_tokens, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_index :user_tokens, [:token], unique: true

  end
end
