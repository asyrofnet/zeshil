class CreateMobileAppsVersionTable < ActiveRecord::Migration[5.0]
  def change
    create_table :mobile_apps_versions do |t|
      t.string :version, null: false
      t.string :platform
      t.integer :application_id, null: true

      t.timestamps null: false
    end

    add_index :mobile_apps_versions, [:platform, :application_id], unique: true
    add_foreign_key :mobile_apps_versions, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade

  end
end
