class CreateLikesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :likes do |t|
      t.integer :user_id, null: false, comment: "Like's creator."
      t.integer :post_id, null: false, comment: "Post which be liked."

      t.timestamps
    end

    add_foreign_key :likes, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :likes, :posts, column: :post_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
