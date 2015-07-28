Joruri::Application.routes.draw do
  scp = "admin"
  mod = "sys"
  
  ## script
  match "/_script/#{mod}/run/*paths" => "#{mod}/script/runner#run"
  
  scope "_#{scp}" do
    namespace mod do
      scope :module => scp do
        ## admin
        resources "maintenances",
          :controller => "maintenances",
          :path => "maintenances"
        resources "messages",
          :controller => "messages",
          :path => "messages"
        resources "languages",
          :controller => "languages",
          :path => "languages"
        resources "ldap_groups",
          :controller => "ldap_groups",
          :path => ":parent/ldap_groups"
        resources "ldap_users",
          :controller => "ldap_users",
          :path => ":parent/ldap_users"
        resources "ldap_synchros",
          :controller => "ldap_synchros",
          :path => "ldap_synchros" do
            member do
              get :synchronize
              post :synchronize
              put :synchronize
              delete :synchronize
            end
          end
        resources "users",
          :controller => "users",
          :path => "users"
        resources "groups",
          :controller => "groups",
          :path => ":parent/groups" do
            collection do
              get :assign_sort_no
            end
          end
        resources "group_users",
          :controller => "group_users",
          :path => ":parent/group_users"
        resources "export_groups",
          :controller => "groups/export",
          :path => "export_groups" do
            collection do
              get :export
              post :export
              put :export
              delete :export
            end
          end
        resources "import_groups",
          :controller => "groups/import",
          :path => "import_groups" do
            collection do
              get :import
              post :import
              put :import
              delete :import
            end
          end
        resources "role_names",
          :controller => "role_names",
          :path => "role_names"
        resources "object_privileges",
          :controller => "object_privileges",
          :path => ":parent/object_privileges"
        resources "inline_files",
          :controller => "inline/files",
          :path => ":parent/inline_files" do
            member do
              get :download
            end
          end
        resources "docs",
          :controller => "docs",
          :path => "docs"
        resources "switch_users",
          :controller => "switch_users",
          :path => "switch_users" do
            collection do
              post :import
            end
          end
        resources "product_synchros",
          :controller => "product_synchros",
          :path => "product_synchros" do
            collection do
              get :synchronize
              post :synchronize
            end
          end
        match ":parent/inline_files/files/(:name(.:format))" => "inline/files#download"
      end
    end
  end
end