class UpdateWebmailFiltersForJunkMailbox < ActiveRecord::Migration[5.0]
  def up
    execute "update webmail_filters set action = 'move', mailbox_name = 'Junk' where name = '* 迷惑メール' and action = 'delete'"
  end
  def down
    execute "update webmail_filters set action = 'delete', mailbox_name = '' where name = '* 迷惑メール' and action = 'move' and mailbox_name = 'Junk'"
  end
end
