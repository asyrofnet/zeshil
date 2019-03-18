class CreateSmsVerificationLogsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :sms_verification_logs do |t|
      t.integer :user_id, null: false
      t.integer :provider_id, null: false
      t.text :content, null: true
      t.boolean :is_success, default: false
      t.timestamps
    end

    add_foreign_key :sms_verification_logs, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :sms_verification_logs, :providers, column: :provider_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
