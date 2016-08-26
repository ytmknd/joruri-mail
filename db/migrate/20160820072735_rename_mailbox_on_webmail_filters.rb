class RenameMailboxOnWebmailFilters < ActiveRecord::Migration[5.0]
  def change
    rename_column :webmail_filters, :mailbox, :mailbox_name
  end
end
