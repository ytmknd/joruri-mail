class CreateSysTenants < ActiveRecord::Migration[5.0]
  def change
    create_table :sys_tenants do |t|
      t.string  :code, index: true
      t.string  :name
      t.string  :mail_domain
      t.string  :default_pass_limit
      t.string  :default_pass_prefix
      t.integer :mobile_access
      t.timestamps
    end
  end
end
