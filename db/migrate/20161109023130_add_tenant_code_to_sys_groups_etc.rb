class AddTenantCodeToSysGroupsEtc < ActiveRecord::Migration[5.0]
  def change
    [:sys_groups, :sys_ldap_synchros].each do |table|
      add_column table, :tenant_code, :string, after: :id
      add_index table, :tenant_code
    end
  end
end
