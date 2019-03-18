class CreateCommentMediaTable < ActiveRecord::Migration[5.0]
  def change
    create_table :comment_media do |t|
      t.integer :comment_id
      t.string :content_type, null: false
      t.string :media_type, null: false
      t.string :sub_type, null: false
      t.integer :size, null: false, comment: "In bytes"
      t.string :original_filename, null: false
      t.string :compressed_link, null: false
      t.string :link, null: false
      t.timestamps
    end

    add_foreign_key :comment_media, :comments, column: :comment_id, primary_key: :id, on_delete: :cascade, on_update: :cascade

    # follow this tutorial http://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails
    # as jsonb will faster to read than json
    add_column :comment_media, :additional_info, :jsonb, null: false, default: '{}'
    add_index  :comment_media, :additional_info, using: :gin
  end
end
