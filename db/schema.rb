# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160729041722) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "gw_webmail_address_groupings", force: :cascade do |t|
    t.integer  "group_id",   limit: 4, null: false
    t.integer  "address_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "gw_webmail_address_groupings", ["address_id"], name: "address_id", using: :btree
  add_index "gw_webmail_address_groupings", ["group_id"], name: "group_id", using: :btree

  create_table "gw_webmail_address_groups", force: :cascade do |t|
    t.integer  "parent_id",  limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level_no",   limit: 4
    t.string   "name",       limit: 255
  end

  add_index "gw_webmail_address_groups", ["user_id"], name: "user_id", using: :btree

  create_table "gw_webmail_addresses", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.integer  "group_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",              limit: 255
    t.string   "email",             limit: 255
    t.text     "memo",              limit: 65535
    t.string   "kana",              limit: 255
    t.string   "company_name",      limit: 255
    t.string   "company_kana",      limit: 255
    t.string   "official_position", limit: 255
    t.string   "company_tel",       limit: 255
    t.string   "company_fax",       limit: 255
    t.string   "company_zip_code",  limit: 255
    t.string   "company_address",   limit: 255
    t.string   "tel",               limit: 255
    t.string   "fax",               limit: 255
    t.string   "zip_code",          limit: 255
    t.string   "address",           limit: 255
    t.string   "mobile_tel",        limit: 255
    t.string   "uri",               limit: 255
    t.integer  "sort_no",           limit: 4
  end

  add_index "gw_webmail_addresses", ["user_id", "group_id"], name: "user_id", using: :btree

  create_table "gw_webmail_docs", force: :cascade do |t|
    t.string   "state",        limit: 15
    t.integer  "sort_no",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title",        limit: 65535
    t.text     "body",         limit: 65535
  end

  create_table "gw_webmail_filter_conditions", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "filter_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no",    limit: 4
    t.string   "column",     limit: 15
    t.string   "inclusion",  limit: 15
    t.string   "value",      limit: 255
  end

  add_index "gw_webmail_filter_conditions", ["user_id", "filter_id"], name: "user_id", using: :btree

  create_table "gw_webmail_filters", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.string   "state",            limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no",          limit: 4
    t.string   "name",             limit: 255
    t.string   "action",           limit: 15
    t.string   "mailbox",          limit: 255
    t.string   "conditions_chain", limit: 15
  end

  add_index "gw_webmail_filters", ["user_id"], name: "user_id", using: :btree

  create_table "gw_webmail_mail_address_histories", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "address",          limit: 255
    t.string   "friendly_address", limit: 255
  end

  add_index "gw_webmail_mail_address_histories", ["user_id"], name: "user_id", using: :btree

  create_table "gw_webmail_mail_nodes", force: :cascade do |t|
    t.integer  "user_id",                         limit: 4
    t.integer  "uid",                             limit: 4
    t.text     "mailbox",                         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "message_date"
    t.text     "from",                            limit: 65535
    t.text     "to",                              limit: 65535
    t.text     "cc",                              limit: 65535
    t.text     "bcc",                             limit: 65535
    t.text     "subject",                         limit: 65535
    t.boolean  "has_attachments"
    t.integer  "size",                            limit: 4
    t.boolean  "has_disposition_notification_to"
    t.integer  "ref_uid",                         limit: 4
    t.text     "ref_mailbox",                     limit: 65535
  end

  add_index "gw_webmail_mail_nodes", ["user_id", "uid", "mailbox"], name: "user_id", length: {"user_id"=>nil, "uid"=>nil, "mailbox"=>16}, using: :btree

  create_table "gw_webmail_mailboxes", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no",    limit: 4
    t.text     "name",       limit: 65535
    t.text     "title",      limit: 65535
    t.integer  "messages",   limit: 4
    t.integer  "unseen",     limit: 4
    t.integer  "recent",     limit: 4
  end

  add_index "gw_webmail_mailboxes", ["user_id", "sort_no"], name: "user_id", using: :btree

  create_table "gw_webmail_settings", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.text     "value",      limit: 4294967295
  end

  add_index "gw_webmail_settings", ["user_id", "name"], name: "user_id", using: :btree

  create_table "gw_webmail_signs", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level_no",     limit: 4
    t.string   "name",         limit: 255
    t.text     "body",         limit: 65535
    t.integer  "default_flag", limit: 4
  end

  add_index "gw_webmail_signs", ["user_id"], name: "user_id", using: :btree

  create_table "gw_webmail_templates", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",         limit: 255
    t.text     "from",         limit: 65535
    t.text     "to",           limit: 65535
    t.text     "cc",           limit: 65535
    t.text     "bcc",          limit: 65535
    t.text     "subject",      limit: 65535
    t.text     "body",         limit: 65535
    t.integer  "default_flag", limit: 4
  end

  add_index "gw_webmail_templates", ["user_id"], name: "user_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "sys_files", force: :cascade do |t|
    t.integer  "unid",         limit: 4
    t.string   "tmp_id",       limit: 255
    t.integer  "parent_unid",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",         limit: 255
    t.text     "title",        limit: 65535
    t.text     "mime_type",    limit: 65535
    t.integer  "size",         limit: 4
    t.integer  "image_is",     limit: 4
    t.integer  "image_width",  limit: 4
    t.integer  "image_height", limit: 4
  end

  add_index "sys_files", ["parent_unid", "name"], name: "parent_unid", using: :btree

  create_table "sys_groups", force: :cascade do |t|
    t.string   "state",        limit: 15
    t.string   "web_state",    limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",    limit: 4,     null: false
    t.integer  "level_no",     limit: 4
    t.string   "code",         limit: 255,   null: false
    t.integer  "sort_no",      limit: 4
    t.integer  "layout_id",    limit: 4
    t.integer  "ldap",         limit: 4,     null: false
    t.string   "ldap_version", limit: 255
    t.string   "name",         limit: 255
    t.string   "name_en",      limit: 255
    t.string   "tel",          limit: 255
    t.string   "outline_uri",  limit: 255
    t.text     "email",        limit: 65535
    t.string   "group_s_name", limit: 255
  end

  create_table "sys_groups_backups", force: :cascade do |t|
    t.string   "state",        limit: 15
    t.string   "web_state",    limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",    limit: 4,     null: false
    t.integer  "level_no",     limit: 4
    t.string   "code",         limit: 255,   null: false
    t.integer  "sort_no",      limit: 4
    t.integer  "layout_id",    limit: 4
    t.integer  "ldap",         limit: 4,     null: false
    t.string   "ldap_version", limit: 255
    t.string   "name",         limit: 255
    t.string   "name_en",      limit: 255
    t.string   "tel",          limit: 255
    t.string   "outline_uri",  limit: 255
    t.text     "email",        limit: 65535
    t.string   "group_s_name", limit: 255
  end

  create_table "sys_languages", force: :cascade do |t|
    t.string   "state",      limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no",    limit: 4
    t.string   "name",       limit: 255
    t.text     "title",      limit: 65535
  end

  create_table "sys_ldap_synchros", force: :cascade do |t|
    t.integer  "parent_id",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version",           limit: 10
    t.string   "entry_type",        limit: 15
    t.string   "code",              limit: 255
    t.string   "name",              limit: 255
    t.string   "name_en",           limit: 255
    t.string   "email",             limit: 255
    t.string   "kana",              limit: 255
    t.string   "sort_no",           limit: 255
    t.string   "official_position", limit: 255
    t.string   "assigned_job",      limit: 255
    t.string   "group_s_name",      limit: 255
  end

  add_index "sys_ldap_synchros", ["version", "parent_id", "entry_type"], name: "version", using: :btree

  create_table "sys_maintenances", force: :cascade do |t|
    t.integer  "unid",         limit: 4
    t.string   "state",        limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title",        limit: 65535
    t.text     "body",         limit: 65535
  end

  create_table "sys_messages", force: :cascade do |t|
    t.integer  "unid",         limit: 4
    t.string   "state",        limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title",        limit: 65535
    t.text     "body",         limit: 65535
  end

  create_table "sys_sequences", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.integer  "version",    limit: 4
    t.integer  "value",      limit: 4
  end

  add_index "sys_sequences", ["name", "version"], name: "name", using: :btree

  create_table "sys_user_logins", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sys_user_logins", ["user_id"], name: "user_id", using: :btree

  create_table "sys_users", force: :cascade do |t|
    t.text     "air_login_id",              limit: 65535
    t.string   "state",                     limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ldap",                      limit: 4,     null: false
    t.string   "ldap_version",              limit: 255
    t.integer  "auth_no",                   limit: 4,     null: false
    t.string   "name",                      limit: 255
    t.string   "name_en",                   limit: 255
    t.string   "account",                   limit: 255
    t.string   "password",                  limit: 255
    t.integer  "mobile_access",             limit: 4
    t.string   "mobile_password",           limit: 255
    t.string   "email",                     limit: 255
    t.text     "remember_token",            limit: 65535
    t.datetime "remember_token_expires_at"
    t.string   "kana",                      limit: 255
    t.string   "sort_no",                   limit: 255
    t.string   "official_position",         limit: 255
    t.string   "assigned_job",              limit: 255
    t.string   "group_s_name",              limit: 255
  end

  create_table "sys_users_backups", force: :cascade do |t|
    t.text     "air_login_id",              limit: 65535
    t.string   "state",                     limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ldap",                      limit: 4,     null: false
    t.string   "ldap_version",              limit: 255
    t.integer  "auth_no",                   limit: 4,     null: false
    t.string   "name",                      limit: 255
    t.string   "name_en",                   limit: 255
    t.string   "account",                   limit: 255
    t.string   "password",                  limit: 255
    t.integer  "mobile_access",             limit: 4
    t.string   "mobile_password",           limit: 255
    t.string   "email",                     limit: 255
    t.text     "remember_token",            limit: 65535
    t.datetime "remember_token_expires_at"
    t.string   "kana",                      limit: 255
    t.string   "sort_no",                   limit: 255
    t.string   "official_position",         limit: 255
    t.string   "assigned_job",              limit: 255
    t.string   "group_s_name",              limit: 255
  end

  create_table "sys_users_groups", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",    limit: 4
    t.integer  "group_id",   limit: 4
  end

  add_index "sys_users_groups", ["user_id", "group_id"], name: "user_id", using: :btree

  create_table "sys_users_groups_backups", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",    limit: 4
    t.integer  "group_id",   limit: 4
  end

  add_index "sys_users_groups_backups", ["user_id", "group_id"], name: "user_id", using: :btree

end
