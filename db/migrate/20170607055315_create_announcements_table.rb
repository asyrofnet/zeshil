class CreateAnnouncementsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :announcements do |t|
    	t.text :text_content
	    t.string :announcement_image_url
	    t.string :button_text
	    t.string :button_url
	    t.string :announcement_type, default: "", null: false
	    t.boolean :is_active, default: true, null: false
      	t.integer :application_id, null: false
	    t.timestamps
    end

    add_foreign_key :announcements, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
