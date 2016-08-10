class AddPriorityToWebmailMailNodes < ActiveRecord::Migration[5.0]
  def change
    add_column :webmail_mail_nodes, :priority, :string, limit: 1
  end
end
