class CreateProvidersTable < ActiveRecord::Migration[5.1]
  def change
    create_table :providers do |t|
      t.string :provider_name, null: false
      t.timestamps null: false
    end
  end
end
