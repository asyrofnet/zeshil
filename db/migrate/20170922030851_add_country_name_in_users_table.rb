class AddCountryNameInUsersTable < ActiveRecord::Migration[5.1]
  def change
		add_column :users, :country_name, :string, null: true, default: ""
  end
end
