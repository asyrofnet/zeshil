class AddPhonenumberToBroadcastReceiptHistories < ActiveRecord::Migration[5.1]
  def change
    add_column :broadcast_receipt_histories, :phonenumber, :string, null: false
  end
end
