class ChangeMessagesUnseenRecentDefaultValuesOnWebmailMailboxes < ActiveRecord::Migration[5.0]
  def change
    change_column :webmail_mailboxes, :messages, :integer, default: 0
    change_column :webmail_mailboxes, :unseen, :integer, default: 0
    change_column :webmail_mailboxes, :recent, :integer, default: 0
  end
end
