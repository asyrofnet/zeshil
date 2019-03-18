class CreateApplicationsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :applications do |t|
      t.string :app_id, null: false
      t.string :app_name, null: false
      t.text :description, null: true
      t.string :qiscus_sdk_url, null: false
      t.timestamps
    end

    add_index :applications, :app_id, :unique => true
  end
end
