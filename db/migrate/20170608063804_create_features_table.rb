class CreateFeaturesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :features do |t|
      t.string :feature_id, null: false
      t.string :feature_name, null: false
      t.text :description, null: true
      t.integer :application_id, null: false
      t.timestamps
    end

    add_index :features, :feature_id, :unique => true
    add_foreign_key :features, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
