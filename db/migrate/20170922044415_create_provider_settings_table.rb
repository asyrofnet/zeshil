class CreateProviderSettingsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :provider_settings do |t|
      t.integer :attempt, null: false
      t.integer :provider_id, null: true
      t.integer :application_id, null: true
      t.timestamps null: false
    end

    add_index :provider_settings, [:attempt, :application_id], unique: true
    add_foreign_key :provider_settings, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :provider_settings, :providers, column: :provider_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
