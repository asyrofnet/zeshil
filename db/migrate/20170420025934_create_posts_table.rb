class CreatePostsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.integer :user_id, null: false, comment: "Post maker"
      t.text :content, default: "", comment: "Default is empty string to make user can shared another post without caption"
      t.integer :post_id, null: true, comment: "Set null if it is independent post (not shared post by other user) or if parent post has been deleted."
      t.integer :share_referrer_id, null: true, comment: "User id yang telah meng-share post itu sebelumnya, lalu di post lagi oleh :user_id"
      t.boolean :is_shared_post, null: false, default: false, comment: "Status whether this post is shared post or independent post. If true, 'post_id' must not be null, but if it is null, then may be the post already been deleted by it's maker."
      t.boolean :is_public_post, null: false, default: true, comment: "Status whether this post is public or not"
      t.timestamps
    end

    add_foreign_key :posts, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :posts, :posts, column: :post_id, primary_key: :id, on_delete: :nullify, on_update: :nullify
    add_foreign_key :posts, :users, column: :share_referrer_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
