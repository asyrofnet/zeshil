class CreateCustomMenus < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_menus do |t|
      t.string :caption, null: true
      t.text :link, null: true
      t.integer :application_id, null: false
      t.timestamps
    end

    add_foreign_key :custom_menus, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
