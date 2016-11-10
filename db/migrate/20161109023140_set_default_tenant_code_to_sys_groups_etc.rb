class SetDefaultTenantCodeToSysGroupsEtc < ActiveRecord::Migration[5.0]
  def up
    [:sys_groups].each do |table|
      execute "update #{table} set tenant_code = 'soshiki'"
    end
  end
end
