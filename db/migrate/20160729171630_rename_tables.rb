class RenameTables < ActiveRecord::Migration
  def change
    tables = [
      :webmail_addresses,
      :webmail_address_groupings,
      :webmail_address_groups,
      :webmail_docs,
      :webmail_filters,
      :webmail_filter_conditions,
      :webmail_mailboxes,
      :webmail_mail_address_histories,
      :webmail_mail_nodes,
      :webmail_settings,
      :webmail_signs,
      :webmail_templates
    ]
    tables.each do |table|
      rename_table "gw_#{table}", table
    end
  end
end
