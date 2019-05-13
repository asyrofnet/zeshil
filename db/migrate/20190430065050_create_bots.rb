class CreateBots < ActiveRecord::Migration[5.1]
  def change
    create_table :bots do |t|
      t.string :username, null: false
      t.string :password_digest, null: false
      t.string :description, null: true
      t.integer :user_id, null: false, comment: 'detail of bot'
      t.integer :creator_id, null: false, comment: 'bot creator'
      t.timestamps
    end

    add_index :bots, :username, unique: true
    add_foreign_key :bots, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :bots, :users, column: :creator_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
