class AddFeatureIdAndApplicationIdIndexInFeatureTable < ActiveRecord::Migration[5.1]
  def change
    remove_index :features, :feature_id
    add_index :features, [:feature_id, :application_id], unique: true
  end
end
