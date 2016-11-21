Joruri::Application.routes.draw do
  scope '_admin' do
    namespace 'sys' do
      scope module: 'admin' do
        ## admin
        resources :maintenances
        resources :messages
        resources :languages
        resources :ldap_groups, path: ':parent/ldap_groups'
        resources :ldap_synchros do
          member do
            get :synchronize
            post :synchronize
          end
        end
        resources :tenants
        resources :users
        resources :groups, path: ':parent/groups' do
          collection do
            get :assign_sort_no
          end
        end
        resources :group_users, path: ':parent/group_users'
        resources :export_groups, controller: 'groups/export' do
          collection do
            get :export
            post :export
          end
        end
        resources :import_groups, controller: 'groups/import' do
          collection do
            get :import
            post :import
          end
        end
        resources :docs
        resources :switch_users do
          collection do
            post :import
          end
        end
        resources :product_synchros do
          collection do
            get :synchronize
            post :synchronize
          end
        end
        resources :tests do
          collection do
            get :timeout
          end
        end
      end
    end
  end
end
