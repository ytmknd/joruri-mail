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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101025002218) do

  create_table "gw_webmail_address_groupings", :force => true do |t|
    t.integer  "group_id",   :null => false
    t.integer  "address_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "gw_webmail_address_groupings", ["address_id"], :name => "address_id"
  add_index "gw_webmail_address_groupings", ["group_id"], :name => "group_id"

  create_table "gw_webmail_address_groups", :force => true do |t|
    t.integer  "parent_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level_no"
    t.string   "name"
  end

  add_index "gw_webmail_address_groups", ["user_id"], :name => "user_id"

  create_table "gw_webmail_addresses", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "email"
    t.text     "memo"
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
  end

  add_index "gw_webmail_addresses", ["user_id", "group_id"], :name => "user_id"

  create_table "gw_webmail_docs", :force => true do |t|
    t.string   "state",        :limit => 15
    t.integer  "sort_no"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title"
    t.text     "body"
  end

  create_table "gw_webmail_filter_conditions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "filter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.string   "column",     :limit => 15
    t.string   "inclusion",  :limit => 15
    t.string   "value"
  end

  add_index "gw_webmail_filter_conditions", ["user_id", "filter_id"], :name => "user_id"

  create_table "gw_webmail_filters", :force => true do |t|
    t.integer  "user_id"
    t.string   "state",            :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.string   "name"
    t.string   "action",           :limit => 15
    t.string   "mailbox"
    t.string   "conditions_chain", :limit => 15
  end

  add_index "gw_webmail_filters", ["user_id"], :name => "user_id"

  create_table "gw_webmail_mail_address_histories", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "address"
    t.string   "friendly_address"
  end

  add_index "gw_webmail_mail_address_histories", ["user_id"], :name => "user_id"

  create_table "gw_webmail_mail_nodes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "uid"
    t.text     "mailbox"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "message_date"
    t.text     "from"
    t.text     "to"
    t.text     "cc"
    t.text     "bcc"
    t.text     "subject"
    t.boolean  "has_attachments"
    t.integer  "size"
    t.boolean  "has_disposition_notification_to"
    t.integer  "ref_uid"
    t.text     "ref_mailbox"
  end

  add_index "gw_webmail_mail_nodes", ["user_id", "uid", "mailbox"], :name => "user_id", :length => {"user_id"=>nil, "uid"=>nil, "mailbox"=>"16"}

  create_table "gw_webmail_mailboxes", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.text     "name"
    t.text     "title"
    t.integer  "messages"
    t.integer  "unseen"
    t.integer  "recent"
  end

  add_index "gw_webmail_mailboxes", ["user_id", "sort_no"], :name => "user_id"

  create_table "gw_webmail_settings", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "value",      :limit => 2147483647
  end

  add_index "gw_webmail_settings", ["user_id", "name"], :name => "user_id"

  create_table "gw_webmail_signs", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level_no"
    t.string   "name"
    t.text     "body"
    t.integer  "default_flag"
  end

  add_index "gw_webmail_signs", ["user_id"], :name => "user_id"

  create_table "gw_webmail_templates", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "from"
    t.text     "to"
    t.text     "cc"
    t.text     "bcc"
    t.text     "subject"
    t.text     "body"
    t.integer  "default_flag"
  end

  add_index "gw_webmail_templates", ["user_id"], :name => "user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sys_creators", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "group_id"
  end

  create_table "sys_editable_groups", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "group_ids"
  end

  create_table "sys_files", :force => true do |t|
    t.integer  "unid"
    t.string   "tmp_id"
    t.integer  "parent_unid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "title"
    t.text     "mime_type"
    t.integer  "size"
    t.integer  "image_is"
    t.integer  "image_width"
    t.integer  "image_height"
  end

  add_index "sys_files", ["parent_unid", "name"], :name => "parent_unid"

  create_table "sys_groups", :force => true do |t|
    t.string   "state",        :limit => 15
    t.string   "web_state",    :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",                  :null => false
    t.integer  "level_no"
    t.string   "code",                       :null => false
    t.integer  "sort_no"
    t.integer  "layout_id"
    t.integer  "ldap",                       :null => false
    t.string   "ldap_version"
    t.string   "name"
    t.string   "name_en"
    t.string   "tel"
    t.string   "outline_uri"
    t.text     "email"
    t.string   "group_s_name"
  end

  create_table "sys_groups_backups", :force => true do |t|
    t.string   "state",        :limit => 15
    t.string   "web_state",    :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",                  :null => false
    t.integer  "level_no"
    t.string   "code",                       :null => false
    t.integer  "sort_no"
    t.integer  "layout_id"
    t.integer  "ldap",                       :null => false
    t.string   "ldap_version"
    t.string   "name"
    t.string   "name_en"
    t.string   "tel"
    t.string   "outline_uri"
    t.text     "email"
    t.string   "group_s_name"
  end

  create_table "sys_languages", :force => true do |t|
    t.string   "state",      :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_no"
    t.string   "name"
    t.text     "title"
  end

  create_table "sys_ldap_synchros", :force => true do |t|
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version",           :limit => 10
    t.string   "entry_type",        :limit => 15
    t.string   "code"
    t.string   "name"
    t.string   "name_en"
    t.string   "email"
    t.string   "kana"
    t.string   "sort_no"
    t.string   "official_position"
    t.string   "assigned_job"
    t.string   "group_s_name"
  end

  add_index "sys_ldap_synchros", ["version", "parent_id", "entry_type"], :name => "version"

  create_table "sys_maintenances", :force => true do |t|
    t.integer  "unid"
    t.string   "state",        :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title"
    t.text     "body"
  end

  create_table "sys_messages", :force => true do |t|
    t.integer  "unid"
    t.string   "state",        :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text     "title"
    t.text     "body"
  end

  create_table "sys_object_privileges", :force => true do |t|
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "item_unid"
    t.string   "action",     :limit => 15
  end

  add_index "sys_object_privileges", ["item_unid", "action"], :name => "item_unid"

  create_table "sys_publishers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.string   "name"
    t.text     "published_path"
    t.text     "content_type"
    t.integer  "content_length"
  end

  create_table "sys_recognitions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "recognizer_ids"
    t.text     "info_xml"
  end

  add_index "sys_recognitions", ["user_id"], :name => "user_id"

  create_table "sys_role_names", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "title"
  end

  create_table "sys_sequences", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "version"
    t.integer  "value"
  end

  add_index "sys_sequences", ["name", "version"], :name => "name"

  create_table "sys_tasks", :force => true do |t|
    t.integer  "unid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "process_at"
    t.string   "name"
  end

  create_table "sys_unids", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "model",      :null => false
    t.integer  "item_id"
  end

  create_table "sys_user_logins", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sys_user_logins", ["user_id"], :name => "user_id"

  create_table "sys_users", :force => true do |t|
    t.text     "air_login_id"
    t.string   "state",                     :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ldap",                                    :null => false
    t.string   "ldap_version"
    t.integer  "auth_no",                                 :null => false
    t.string   "name"
    t.string   "name_en"
    t.string   "account"
    t.string   "password"
    t.integer  "mobile_access"
    t.string   "mobile_password"
    t.string   "email"
    t.text     "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "kana"
    t.string   "sort_no"
    t.string   "official_position"
    t.string   "assigned_job"
    t.string   "group_s_name"
  end

  create_table "sys_users_backups", :force => true do |t|
    t.text     "air_login_id"
    t.string   "state",                     :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ldap",                                    :null => false
    t.string   "ldap_version"
    t.integer  "auth_no",                                 :null => false
    t.string   "name"
    t.string   "name_en"
    t.string   "account"
    t.string   "password"
    t.integer  "mobile_access"
    t.string   "mobile_password"
    t.string   "email"
    t.text     "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "kana"
    t.string   "sort_no"
    t.string   "official_position"
    t.string   "assigned_job"
    t.string   "group_s_name"
  end

  create_table "sys_users_groups", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "group_id"
  end

  add_index "sys_users_groups", ["user_id", "group_id"], :name => "user_id"

  create_table "sys_users_groups_backups", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "group_id"
  end

  add_index "sys_users_groups_backups", ["user_id", "group_id"], :name => "user_id"

  create_table "sys_users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "sys_users_roles", ["user_id", "role_id"], :name => "user_id"

end
