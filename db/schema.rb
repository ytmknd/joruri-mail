# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_19_215321) do
  create_table "delayed_jobs", charset: "utf8", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at", precision: nil
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "sessions", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "sys_files", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "image_height"
    t.integer "image_is"
    t.integer "image_width"
    t.text "mime_type"
    t.string "name"
    t.integer "parent_unid"
    t.integer "size"
    t.text "title"
    t.string "tmp_id"
    t.integer "unid"
    t.datetime "updated_at", precision: nil
    t.index ["parent_unid", "name"], name: "parent_unid"
  end

  create_table "sys_groups", charset: "utf8", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", precision: nil
    t.text "email"
    t.string "group_s_name"
    t.integer "layout_id"
    t.integer "ldap", null: false
    t.string "ldap_version"
    t.integer "level_no"
    t.string "name"
    t.string "name_en"
    t.string "outline_uri"
    t.integer "parent_id", null: false
    t.integer "sort_no"
    t.string "state", limit: 15
    t.string "tel"
    t.datetime "updated_at", precision: nil
    t.string "web_state", limit: 15
  end

  create_table "sys_groups_backups", charset: "utf8", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", precision: nil
    t.text "email"
    t.string "group_s_name"
    t.integer "layout_id"
    t.integer "ldap", null: false
    t.string "ldap_version"
    t.integer "level_no"
    t.string "name"
    t.string "name_en"
    t.string "outline_uri"
    t.integer "parent_id", null: false
    t.integer "sort_no"
    t.string "state", limit: 15
    t.string "tel"
    t.datetime "updated_at", precision: nil
    t.string "web_state", limit: 15
  end

  create_table "sys_languages", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "name"
    t.integer "sort_no"
    t.string "state", limit: 15
    t.text "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "sys_ldap_synchros", charset: "utf8", force: :cascade do |t|
    t.string "assigned_job"
    t.string "code"
    t.datetime "created_at", precision: nil
    t.string "email"
    t.string "entry_type", limit: 15
    t.string "group_s_name"
    t.string "kana"
    t.string "name"
    t.string "name_en"
    t.string "official_position"
    t.integer "parent_id"
    t.string "sort_no"
    t.datetime "updated_at", precision: nil
    t.string "version", limit: 10
    t.index ["version", "parent_id", "entry_type"], name: "version"
  end

  create_table "sys_maintenances", charset: "utf8", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil
    t.datetime "published_at", precision: nil
    t.string "state", limit: 15
    t.text "title"
    t.integer "unid"
    t.datetime "updated_at", precision: nil
  end

  create_table "sys_messages", charset: "utf8", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil
    t.datetime "published_at", precision: nil
    t.string "state", limit: 15
    t.text "title"
    t.integer "unid"
    t.datetime "updated_at", precision: nil
  end

  create_table "sys_sequences", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "name"
    t.datetime "updated_at", precision: nil
    t.integer "value"
    t.integer "version"
    t.index ["name", "version"], name: "name"
  end

  create_table "sys_user_logins", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "sys_users", charset: "utf8", force: :cascade do |t|
    t.string "account"
    t.text "air_login_id"
    t.string "assigned_job"
    t.integer "auth_no", null: false
    t.datetime "created_at", precision: nil
    t.string "email"
    t.string "group_s_name"
    t.string "kana"
    t.integer "ldap", null: false
    t.string "ldap_version"
    t.integer "mobile_access"
    t.string "mobile_password"
    t.string "name"
    t.string "name_en"
    t.string "official_position"
    t.string "password"
    t.text "remember_token"
    t.datetime "remember_token_expires_at", precision: nil
    t.string "sort_no"
    t.string "state", limit: 15
    t.datetime "updated_at", precision: nil
  end

  create_table "sys_users_backups", charset: "utf8", force: :cascade do |t|
    t.string "account"
    t.text "air_login_id"
    t.string "assigned_job"
    t.integer "auth_no", null: false
    t.datetime "created_at", precision: nil
    t.string "email"
    t.string "group_s_name"
    t.string "kana"
    t.integer "ldap", null: false
    t.string "ldap_version"
    t.integer "mobile_access"
    t.string "mobile_password"
    t.string "name"
    t.string "name_en"
    t.string "official_position"
    t.string "password"
    t.text "remember_token"
    t.datetime "remember_token_expires_at", precision: nil
    t.string "sort_no"
    t.string "state", limit: 15
    t.datetime "updated_at", precision: nil
  end

  create_table "sys_users_groups", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "group_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id", "group_id"], name: "user_id"
  end

  create_table "sys_users_groups_backups", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "group_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id", "group_id"], name: "user_id"
  end

  create_table "webmail_address_groupings", charset: "utf8", force: :cascade do |t|
    t.integer "address_id", null: false
    t.datetime "created_at", precision: nil
    t.integer "group_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["address_id"], name: "address_id"
    t.index ["group_id"], name: "group_id"
  end

  create_table "webmail_address_groups", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "level_no"
    t.string "name"
    t.integer "parent_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "webmail_addresses", charset: "utf8", force: :cascade do |t|
    t.string "address"
    t.string "company_address"
    t.string "company_fax"
    t.string "company_kana"
    t.string "company_name"
    t.string "company_tel"
    t.string "company_zip_code"
    t.datetime "created_at", precision: nil
    t.string "email"
    t.string "fax"
    t.integer "group_id"
    t.string "kana"
    t.text "memo"
    t.string "mobile_tel"
    t.string "name"
    t.string "official_position"
    t.integer "sort_no"
    t.string "tel"
    t.datetime "updated_at", precision: nil
    t.string "uri"
    t.integer "user_id"
    t.string "zip_code"
    t.index ["user_id", "group_id"], name: "user_id"
  end

  create_table "webmail_docs", charset: "utf8", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil
    t.datetime "published_at", precision: nil
    t.integer "sort_no"
    t.string "state", limit: 15
    t.text "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "webmail_filter_conditions", charset: "utf8", force: :cascade do |t|
    t.string "column", limit: 15
    t.datetime "created_at", precision: nil
    t.integer "filter_id"
    t.string "inclusion", limit: 15
    t.integer "sort_no"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "value"
    t.index ["user_id", "filter_id"], name: "user_id"
  end

  create_table "webmail_filters", charset: "utf8", force: :cascade do |t|
    t.string "action", limit: 15
    t.string "conditions_chain", limit: 15
    t.datetime "created_at", precision: nil
    t.string "mailbox_name"
    t.string "name"
    t.integer "sort_no"
    t.string "state", limit: 15
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "webmail_mail_address_histories", charset: "utf8", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", precision: nil
    t.string "friendly_address"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "webmail_mail_nodes", charset: "utf8", force: :cascade do |t|
    t.text "bcc"
    t.text "cc"
    t.datetime "created_at", precision: nil
    t.text "from"
    t.boolean "has_attachments"
    t.boolean "has_disposition_notification_to"
    t.text "mailbox"
    t.datetime "message_date", precision: nil
    t.string "priority", limit: 1
    t.text "ref_mailbox"
    t.integer "ref_uid"
    t.integer "size"
    t.text "subject"
    t.text "to"
    t.integer "uid"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id", "uid", "mailbox"], name: "user_id", length: { mailbox: 16 }
  end

  create_table "webmail_mailboxes", charset: "utf8", force: :cascade do |t|
    t.text "attr"
    t.datetime "created_at", precision: nil
    t.text "delim"
    t.integer "messages", default: 0
    t.text "name"
    t.integer "recent", default: 0
    t.integer "sort_no"
    t.text "special_use"
    t.text "title"
    t.integer "unseen", default: 0
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id", "sort_no"], name: "user_id"
  end

  create_table "webmail_quota_roots", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "mailbox"
    t.integer "quota"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "usage"
    t.integer "user_id"
    t.index ["user_id"], name: "index_webmail_quota_roots_on_user_id"
  end

  create_table "webmail_settings", charset: "utf8", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "name"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.text "value", size: :long
    t.index ["user_id", "name"], name: "user_id"
  end

  create_table "webmail_signs", charset: "utf8", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil
    t.integer "default_flag"
    t.integer "level_no"
    t.string "name"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "webmail_templates", charset: "utf8", force: :cascade do |t|
    t.text "bcc"
    t.text "body"
    t.text "cc"
    t.datetime "created_at", precision: nil
    t.integer "default_flag"
    t.text "from"
    t.string "name"
    t.text "subject"
    t.text "to"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id"], name: "user_id"
  end
end
