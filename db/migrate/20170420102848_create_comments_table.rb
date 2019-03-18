class CreateCommentsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.integer :user_id, null: false, comment: "Comment's creator."
      t.integer :post_id, null: false, comment: "Post which be commented."
      t.integer :comment_id, null: true, comment: "For nested comment."

      t.text :content, null: false, comment: "Comment content."
      t.timestamps
    end

    add_foreign_key :comments, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :comments, :posts, column: :post_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :comments, :comments, column: :comment_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
