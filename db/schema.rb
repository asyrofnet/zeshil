# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190905065331) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "announcements", force: :cascade do |t|
    t.text "text_content"
    t.string "announcement_image_url"
    t.string "button_text"
    t.string "button_url"
    t.string "announcement_type", default: "", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "applications", id: :serial, force: :cascade do |t|
    t.string "app_id", null: false
    t.string "app_name", null: false
    t.text "description"
    t.string "qiscus_sdk_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qiscus_sdk_secret", default: "", null: false
    t.string "sms_sender", default: ""
    t.string "server_key", default: ""
    t.string "fcm_key", default: ""
    t.string "apns_cert_dev", default: ""
    t.string "apns_cert_prod", default: ""
    t.string "apns_cert_password", default: ""
    t.string "apns_cert_topic", default: ""
    t.boolean "is_auto_friend", default: false
    t.boolean "is_send_message_pn", default: false
    t.boolean "is_send_call_pn", default: false
    t.boolean "is_coaching_module_connected", default: false
    t.string "default_locale", default: "en"
    t.boolean "is_locale_activated", default: false
    t.index ["app_id"], name: "index_applications_on_app_id", unique: true
  end

  create_table "auth_sessions", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "jwt_token", null: false
    t.string "ip_address", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "country_code", default: "", null: false
    t.string "country_name", default: "", null: false
    t.string "region_code", default: "", null: false
    t.string "region_name", default: "", null: false
    t.string "city", default: "", null: false
    t.string "zipcode", default: "", null: false
    t.string "time_zone", default: "", null: false
    t.decimal "latitude", precision: 10, scale: 6, default: "0.0"
    t.decimal "longitude", precision: 10, scale: 6, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bots", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.string "description"
    t.integer "user_id", null: false, comment: "detail of bot"
    t.integer "user_id_creator", null: false, comment: "bot creator"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_bots_on_username", unique: true
  end

  create_table "broadcast_messages", force: :cascade do |t|
    t.text "message"
    t.integer "user_id", null: false
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "broadcast_receipt_histories", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "broadcast_message_id", null: false
    t.datetime "sent_at"
    t.datetime "delivered_at"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phonenumber"
  end

  create_table "call_logs", force: :cascade do |t|
    t.string "call_event", null: false
    t.string "message"
    t.integer "caller_user_id", null: false
    t.integer "callee_user_id", null: false
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "call_room_id", default: " ", null: false
    t.string "duration"
    t.datetime "connected_at"
    t.integer "status", default: 1, null: false
  end

  create_table "chat_rooms", id: :serial, force: :cascade do |t|
    t.string "qiscus_room_name", null: false
    t.integer "qiscus_room_id", null: false
    t.boolean "is_group_chat", default: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "group_chat_name", default: "Chat Name", null: false
    t.integer "application_id"
    t.string "group_avatar_url", default: ""
    t.boolean "is_official_chat", default: false, null: false
    t.integer "target_user_id", default: 0
    t.boolean "is_public_chat", default: false, null: false
    t.boolean "is_channel", default: false
    t.integer "chat_users_count", default: 0
    t.index ["qiscus_room_id", "application_id"], name: "index_chat_rooms_on_qiscus_room_id_and_application_id", unique: true
  end

  create_table "chat_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "chat_room_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_group_admin", default: false, null: false
    t.index ["user_id", "chat_room_id"], name: "index_chat_users_on_user_id_and_chat_room_id", unique: true
  end

  create_table "comment_media", id: :serial, force: :cascade do |t|
    t.integer "comment_id"
    t.string "content_type", null: false
    t.string "media_type", null: false
    t.string "sub_type", null: false
    t.integer "size", null: false, comment: "In bytes"
    t.string "original_filename", null: false
    t.string "compressed_link", null: false
    t.string "link", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "additional_info", default: "{}", null: false
    t.index ["additional_info"], name: "index_comment_media_on_additional_info", using: :gin
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false, comment: "Comment's creator."
    t.integer "post_id", null: false, comment: "Post which be commented."
    t.integer "comment_id", comment: "For nested comment."
    t.text "content", null: false, comment: "Comment content."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "contact_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_favored", default: false, null: false
    t.string "contact_name"
    t.boolean "is_active", default: true
    t.index ["user_id", "contact_id"], name: "index_contacts_on_user_id_and_contact_id", unique: true
  end

  create_table "custom_menus", force: :cascade do |t|
    t.string "caption"
    t.text "url"
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "features", force: :cascade do |t|
    t.string "feature_id", null: false
    t.string "feature_name", null: false
    t.text "description"
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_rolled_out", default: false, null: false
    t.index ["feature_id", "application_id"], name: "index_features_on_feature_id_and_application_id", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.integer "user_id", null: false, comment: "Like's creator."
    t.integer "post_id", null: false, comment: "Post which be liked."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobile_apps_versions", id: :serial, force: :cascade do |t|
    t.string "version", null: false
    t.string "platform"
    t.integer "application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform", "application_id"], name: "index_mobile_apps_versions_on_platform_and_application_id", unique: true
  end

  create_table "mute_chat_rooms", force: :cascade do |t|
    t.integer "chat_room_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_room_id", "user_id"], name: "index_mute_chat_rooms_on_chat_room_id_and_user_id", unique: true
  end

  create_table "pin_chat_rooms", force: :cascade do |t|
    t.integer "chat_room_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_room_id", "user_id"], name: "index_pin_chat_rooms_on_chat_room_id_and_user_id", unique: true
  end

  create_table "post_history", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.text "content", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "post_media", id: :serial, force: :cascade do |t|
    t.integer "post_id", null: false
    t.string "content_type", null: false
    t.string "media_type", null: false
    t.string "sub_type", null: false
    t.integer "size", null: false, comment: "In bytes"
    t.string "original_filename", null: false
    t.string "compressed_link", null: false
    t.string "link", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "additional_info", default: "{}", null: false
    t.index ["additional_info"], name: "index_post_media_on_additional_info", using: :gin
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false, comment: "Post maker"
    t.text "content", default: "", comment: "Default is empty string to make user can shared another post without caption"
    t.integer "post_id", comment: "Set null if it is independent post (not shared post by other user) or if parent post has been deleted."
    t.integer "share_referrer_id", comment: "User id yang telah meng-share post itu sebelumnya, lalu di post lagi oleh :user_id"
    t.boolean "is_shared_post", default: false, null: false, comment: "Status whether this post is shared post or independent post. If true, 'post_id' must not be null, but if it is null, then may be the post already been deleted by it's maker."
    t.boolean "is_public_post", default: true, null: false, comment: "Status whether this post is public or not"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_updated_post", default: false, null: false
  end

  create_table "provider_settings", force: :cascade do |t|
    t.integer "attempt", null: false
    t.integer "provider_id"
    t.integer "application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attempt", "application_id"], name: "index_provider_settings_on_attempt_and_application_id", unique: true
  end

  create_table "providers", force: :cascade do |t|
    t.string "provider_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sms_verification_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "provider_id", null: false
    t.text "content"
    t.boolean "is_success", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_additional_infos", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_user_additional_infos_on_user_id_and_key", unique: true
  end

  create_table "user_dedicated_passcodes", force: :cascade do |t|
    t.string "passcode"
    t.integer "user_id", null: false
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_device_tokens", force: :cascade do |t|
    t.string "devicetoken"
    t.string "user_type"
    t.boolean "is_active", default: true
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["devicetoken"], name: "index_user_device_tokens_on_devicetoken", unique: true
  end

  create_table "user_features", force: :cascade do |t|
    t.integer "user_id"
    t.integer "feature_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "feature_id"], name: "index_user_features_on_user_id_and_feature_id", unique: true
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "phone_number", default: "", null: false
    t.string "passcode", limit: 6
    t.string "fullname"
    t.string "email", default: "", null: false
    t.integer "gender"
    t.date "date_of_birth"
    t.string "avatar_url"
    t.integer "application_id", null: false
    t.boolean "is_public", default: false, null: false
    t.integer "verification_attempts", default: 0
    t.string "qiscus_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qiscus_email", default: "", null: false
    t.text "description", default: ""
    t.string "callback_url", default: ""
    t.integer "lock_version"
    t.string "country_name", default: ""
    t.string "secondary_phone_number", default: ""
    t.string "country_code", default: ""
    t.boolean "deleted", default: false
    t.datetime "deleted_at"
    t.index ["deleted"], name: "index_users_on_deleted"
    t.index ["phone_number", "email", "application_id"], name: "index_users_on_phone_number_and_email_and_application_id", unique: true
    t.index ["secondary_phone_number"], name: "index_users_on_secondary_phone_number"
  end

  add_foreign_key "announcements", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "auth_sessions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bots", "users", column: "user_id_creator", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bots", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "broadcast_messages", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "broadcast_messages", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "broadcast_receipt_histories", "broadcast_messages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "broadcast_receipt_histories", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "call_logs", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "call_logs", "users", column: "callee_user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "call_logs", "users", column: "caller_user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "chat_rooms", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "chat_rooms", "users", column: "target_user_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "chat_rooms", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "chat_users", "chat_rooms", on_update: :cascade, on_delete: :cascade
  add_foreign_key "chat_users", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "comment_media", "comments", on_update: :cascade, on_delete: :cascade
  add_foreign_key "comments", "comments", on_update: :cascade, on_delete: :cascade
  add_foreign_key "comments", "posts", on_update: :cascade, on_delete: :cascade
  add_foreign_key "comments", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "contacts", "users", column: "contact_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "contacts", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "custom_menus", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "features", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "likes", "posts", on_update: :cascade, on_delete: :cascade
  add_foreign_key "likes", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "mobile_apps_versions", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "mute_chat_rooms", "chat_rooms", on_update: :cascade, on_delete: :cascade
  add_foreign_key "mute_chat_rooms", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "pin_chat_rooms", "chat_rooms", on_update: :cascade, on_delete: :cascade
  add_foreign_key "pin_chat_rooms", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "post_history", "posts", on_update: :cascade, on_delete: :cascade
  add_foreign_key "post_history", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "post_media", "posts", on_update: :cascade, on_delete: :cascade
  add_foreign_key "posts", "posts", on_update: :nullify, on_delete: :nullify
  add_foreign_key "posts", "users", column: "share_referrer_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "posts", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "provider_settings", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "provider_settings", "providers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "sms_verification_logs", "providers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "sms_verification_logs", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_additional_infos", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_dedicated_passcodes", "applications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_dedicated_passcodes", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_device_tokens", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_features", "features", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_features", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_roles", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_roles", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users", "applications", on_update: :cascade, on_delete: :cascade
end
