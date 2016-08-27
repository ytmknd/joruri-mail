class CreateWebmailQuotaRoots < ActiveRecord::Migration[5.0]
  def change
    create_table :webmail_quota_roots do |t|
      t.integer    :user_id, index: true
      t.text       :mailbox
      t.integer    :quota
      t.integer    :usage
      t.timestamps
    end
  end
end
