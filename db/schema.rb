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

ActiveRecord::Schema.define(version: 20161110044554) do

  create_table "delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "priority",                 default: 0, null: false
    t.integer  "attempts",                 default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "session_id",               null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", using: :btree
    t.index ["updated_at"], name: "index_sessions_on_updated_at", using: :btree
  end

  create_table "sys_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "unid"
    t.string   "tmp_id"
    t.integer  "parent_unid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "title",        limit: 65535
    t.text     "mime_type",    limit: 65535
    t.integer  "size"
    t.integer  "image_is"
    t.integer  "image_width"
    t.integer  "image_height"
    t.index ["parent_unid", "name"], name: "parent_unid", using: :btree
  end

  create_table "sys_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "tenant_code"
    t.string   "state",        limit: 15
    t.string   "web_state",    limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",                  null: false
    t.integer  "level_no"
    t.string   "code",                       null: false
    t.integer  "sort_no"
    t.integer  "layout_id"
    t.integer  "ldap",                       null: false
    t.string   "ldap_version"
    t.string   "name"
    t.string   "name_en"
    t.string   "tel"
    t.string   "outline_uri"
    t.text     "email",        limit: 65535
    t.string   "group_s_name"
    t.index ["tenant_code"], name: "index_sys_groups_on_tenant_code", using: :btree
  end

  create_table "sys_groups_backups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "state",        limit: 15
    t.string   "web_state",    limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",                  null: false
    t.integer  "level_no"
    t.string   "code",                       null: false
    t.integer  "sort_no"
    t.integer  "layout_id"
    t.integer  "ldap",                       null: false
    t.string   "ldap_version"
    t.string   "name"
    t.string   "name_en"
    t.string   "tel"
    t.string   "outline_uri"
    t.text     "email",        limit: 65535
    t.string   "group_s_name"
  end

  create_table "sys_languages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "state",      limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.string   "name"
    t.text     "title",      limit: 65535
  end

  create_table "sys_ldap_synchros", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "tenant_code"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version",           limit: 10
    t.string   "entry_type",        limit: 15
    t.string   "code"
    t.string   "name"
    t.string   "name_en"
    t.string   "email"
    t.string   "kana"
    t.string   "sort_no"
    t.string   "official_position"
    t.string   "assigned_job"
    t.string   "group_s_name"
    t.index ["tenant_code"], name: "index_sys_ldap_synchros_on_tenant_code", using: :btree
    t.index ["version", "parent_id", "entry_type"], name: "version", using: :btree
  end

  create_table "sys_maintenances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "unid"
    t.string   "state",        limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title",        limit: 65535
    t.text     "body",         limit: 65535
  end

  create_table "sys_messages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "unid"
    t.string   "state",        limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title",        limit: 65535
    t.text     "body",         limit: 65535
  end

  create_table "sys_sequences", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "version"
    t.integer  "value"
    t.index ["name", "version"], name: "name", using: :btree
  end

  create_table "sys_tenants", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code"
    t.string   "name"
    t.string   "mail_domain"
    t.string   "default_pass_limit"
    t.string   "default_pass_prefix"
    t.integer  "mobile_access"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["code"], name: "index_sys_tenants_on_code", using: :btree
  end

  create_table "sys_user_logins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "sys_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "air_login_id",              limit: 65535
    t.string   "state",                     limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ldap",                                    null: false
    t.string   "ldap_version"
    t.integer  "auth_no",                                 null: false
    t.string   "name"
    t.string   "name_en"
    t.string   "account"
    t.string   "password"
    t.integer  "mobile_access"
    t.string   "mobile_password"
    t.string   "email"
    t.text     "remember_token",            limit: 65535
    t.datetime "remember_token_expires_at"
    t.string   "kana"
    t.string   "sort_no"
    t.string   "official_position"
    t.string   "assigned_job"
    t.string   "group_s_name"
  end

  create_table "sys_users_backups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "air_login_id",              limit: 65535
    t.string   "state",                     limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ldap",                                    null: false
    t.string   "ldap_version"
    t.integer  "auth_no",                                 null: false
    t.string   "name"
    t.string   "name_en"
    t.string   "account"
    t.string   "password"
    t.integer  "mobile_access"
    t.string   "mobile_password"
    t.string   "email"
    t.text     "remember_token",            limit: 65535
    t.datetime "remember_token_expires_at"
    t.string   "kana"
    t.string   "sort_no"
    t.string   "official_position"
    t.string   "assigned_job"
    t.string   "group_s_name"
  end

  create_table "sys_users_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "group_id"
    t.index ["user_id", "group_id"], name: "user_id", using: :btree
  end

  create_table "sys_users_groups_backups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "group_id"
    t.index ["user_id", "group_id"], name: "user_id", using: :btree
  end

  create_table "webmail_address_groupings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "group_id",   null: false
    t.integer  "address_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["address_id"], name: "address_id", using: :btree
    t.index ["group_id"], name: "group_id", using: :btree
  end

  create_table "webmail_address_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "parent_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level_no"
    t.string   "name"
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "webmail_addresses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "email"
    t.text     "memo",              limit: 65535
    t.string   "kana"
    t.string   "company_name"
    t.string   "company_kana"
    t.string   "official_position"
    t.string   "company_tel"
    t.string   "company_fax"
    t.string   "company_zip_code"
    t.string   "company_address"
    t.string   "tel"
    t.string   "fax"
    t.string   "zip_code"
    t.string   "address"
    t.string   "mobile_tel"
    t.string   "uri"
    t.integer  "sort_no"
    t.index ["user_id", "group_id"], name: "user_id", using: :btree
  end

  create_table "webmail_docs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "state",        limit: 15
    t.integer  "sort_no"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title",        limit: 65535
    t.text     "body",         limit: 65535
  end

  create_table "webmail_filter_conditions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "filter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.string   "column",     limit: 15
    t.string   "inclusion",  limit: 15
    t.string   "value"
    t.index ["user_id", "filter_id"], name: "user_id", using: :btree
  end

  create_table "webmail_filters", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "state",            limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.string   "name"
    t.string   "action",           limit: 15
    t.string   "mailbox_name"
    t.string   "conditions_chain", limit: 15
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "webmail_mail_address_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "address"
    t.string   "friendly_address"
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "webmail_mail_nodes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "uid"
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
    t.integer  "size"
    t.boolean  "has_disposition_notification_to"
    t.integer  "ref_uid"
    t.text     "ref_mailbox",                     limit: 65535
    t.string   "priority",                        limit: 1
    t.index ["user_id", "uid", "mailbox"], name: "user_id", length: {"user_id"=>nil, "uid"=>nil, "mailbox"=>16}, using: :btree
  end

  create_table "webmail_mailboxes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.text     "name",        limit: 65535
    t.text     "title",       limit: 65535
    t.integer  "messages",                  default: 0
    t.integer  "unseen",                    default: 0
    t.integer  "recent",                    default: 0
    t.text     "delim",       limit: 65535
    t.text     "attr",        limit: 65535
    t.text     "special_use", limit: 65535
    t.index ["user_id", "sort_no"], name: "user_id", using: :btree
  end

  create_table "webmail_quota_roots", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.text     "mailbox",    limit: 65535
    t.integer  "quota"
    t.integer  "usage"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["user_id"], name: "index_webmail_quota_roots_on_user_id", using: :btree
  end

  create_table "webmail_settings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "value",      limit: 4294967295
    t.index ["user_id", "name"], name: "user_id", using: :btree
  end

  create_table "webmail_signs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level_no"
    t.string   "name"
    t.text     "body",         limit: 65535
    t.integer  "default_flag"
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "webmail_templates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "from",         limit: 65535
    t.text     "to",           limit: 65535
    t.text     "cc",           limit: 65535
    t.text     "bcc",          limit: 65535
    t.text     "subject",      limit: 65535
    t.text     "body",         limit: 65535
    t.integer  "default_flag"
    t.index ["user_id"], name: "user_id", using: :btree
  end

end
