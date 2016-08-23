class SetDelimAttrSpecialUseOnWebmailMailboxes < ActiveRecord::Migration[5.0]
  def up
    execute "update webmail_mailboxes set delim = '.'"
    execute "update webmail_mailboxes set special_use = 'Archive' where name = 'Archives'"
    execute "update webmail_mailboxes set special_use = 'Drafts' where name = 'Drafts'"
    execute "update webmail_mailboxes set special_use = 'Sent' where name = 'Sent'"
    execute "update webmail_mailboxes set special_use = 'Trash' where name = 'Trash'"
    execute "update webmail_mailboxes set special_use = 'All' where name = 'virtual.All'"
    execute "update webmail_mailboxes set special_use = 'Flagged' where name = 'virtual.Flagged'"
  end
  def down
  end
end
