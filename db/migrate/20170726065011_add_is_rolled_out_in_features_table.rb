class AddIsRolledOutInFeaturesTable < ActiveRecord::Migration[5.1]
  def change
    add_column :features, :is_rolled_out, :boolean, null: false, default: false
  end
end
