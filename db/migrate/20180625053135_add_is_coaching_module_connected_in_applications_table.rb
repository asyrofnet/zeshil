class AddIsCoachingModuleConnectedInApplicationsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :is_coaching_module_connected, :boolean, default: false
  end
end
