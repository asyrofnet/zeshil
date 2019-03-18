class AddCountryCodeInUsersTable < ActiveRecord::Migration[5.1]
  def change
		add_column :users, :country_code, :string, null: true, default: ""
  end
end
