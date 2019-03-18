class RenameLinkToUrl < ActiveRecord::Migration[5.1]
  def change
    rename_column :custom_menus, :link, :url
  end
end
