class CreateSysLdapSynchroTasks < ActiveRecord::Migration[5.0]
  def change
    create_table :sys_ldap_synchro_tasks do |t|
      t.integer    :version, index: true
      t.string     :target_tenant_code
      t.text       :fetch_log
      t.text       :synchro_log
      t.timestamps
    end
  end
end
