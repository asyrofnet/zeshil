class CreatePostHistoryTable < ActiveRecord::Migration[5.1]
  def change
    create_table :post_history do |t|
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.text :content, default: ""

      t.timestamps
    end

    add_foreign_key :post_history, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :post_history, :posts, column: :post_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
