class CreateUserFeaturesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :user_features do |t|
      t.integer :user_id
      t.integer :feature_id
      t.timestamps
    end

    add_index :user_features, [:user_id, :feature_id], unique: true

    add_foreign_key :user_features, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_features, :features, column: :feature_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
