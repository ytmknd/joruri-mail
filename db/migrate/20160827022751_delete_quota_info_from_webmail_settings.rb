class DeleteQuotaInfoFromWebmailSettings < ActiveRecord::Migration[5.0]
  def up
    execute "delete from webmail_settings where name = 'quota_info'"
  end
end
