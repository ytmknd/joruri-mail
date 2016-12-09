class RenameMobileAccessToAccessControlOnSysTenants < ActiveRecord::Migration[5.0]
  def change
    rename_column :sys_tenants, :mobile_access, :login_control
  end
end
