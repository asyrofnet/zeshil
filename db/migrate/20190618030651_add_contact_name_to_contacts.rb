class AddContactNameToContacts < ActiveRecord::Migration[5.1]
  def change
    add_column :contacts, :contact_name, :string
    add_column :contacts, :is_active, :boolean, :default => true
  end
end
