class AddDelimAttrSpecialUseToWebmailMailboxes < ActiveRecord::Migration[5.0]
  def change
    add_column :webmail_mailboxes, :delim, :text
    add_column :webmail_mailboxes, :attr, :text
    add_column :webmail_mailboxes, :special_use, :text
  end
end
