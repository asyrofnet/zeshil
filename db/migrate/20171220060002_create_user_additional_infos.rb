class CreateUserAdditionalInfos < ActiveRecord::Migration[5.1]
  def change
    create_table :user_additional_infos do |t|
      t.string :key, null: true
      t.text :value, null: true
      t.integer :user_id, null: false
      t.timestamps
    end

    add_foreign_key :user_additional_infos, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
