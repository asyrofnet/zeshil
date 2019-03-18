class CreateAuthSessionsTable < ActiveRecord::Migration[5.0]
  def change
    # to force logout capability
    create_table :auth_sessions do |t|
      t.integer :user_id, null: false
      t.string :jwt_token, null: false
      t.string :ip_address, null: false, default: ""
      t.string :user_agent, null: false, default: ""
      t.string :country_code, null: false, default: ""
      t.string :country_name, null: false, default: ""
      t.string :region_code, null: false, default: ""
      t.string :region_name, null: false, default: ""
      t.string :city, null: false, default: ""
      t.string :zipcode, null: false, default: ""
      t.string :time_zone, null: false, default: ""
      t.decimal :latitude, null: true, default: 0, :precision => 10, :scale => 6
      t.decimal :longitude, null: true, default: 0, :precision => 10, :scale => 6
      t.timestamps
    end

    add_foreign_key :auth_sessions, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
