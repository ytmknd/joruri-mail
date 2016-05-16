class DropObsoleteTables < ActiveRecord::Migration
  def up
    drop_table :sys_creators
    drop_table :sys_editable_groups
    drop_table :sys_object_privileges
    drop_table :sys_publishers
    drop_table :sys_recognitions
    drop_table :sys_role_names
    drop_table :sys_tasks
    drop_table :sys_unids
    drop_table :sys_users_roles
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
