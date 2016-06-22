Joruri::Application.routes.draw do
  mod = "gw"
  scp = "admin"
  
  scope "_#{scp}" do
    namespace mod do
      scope :module => scp do
        ## webmail
        resources "webmail_mails",
          :controller => "webmail/mails",
          :path => "webmail/*mailbox/mails" do
            collection do
              get :empty, :close, :reset_address_history, :star, :label
              post :move, :delete, :seen, :unseen, :register_spam, :mobile_manage, :status
            end
            member do
              get :edit, :answer, :forward, :resend
              post :edit, :answer, :forward, :send_mdn, :mobile_send
            end
          end
        match "webmail/*mailbox/mails/new" => 
          "webmail/mails#new", :via => :post
        resources "webmail_mailboxes",
          :controller => "webmail/mailboxes",
          :path => "webmail/*mailbox/mailboxes"
        match "webmail/*mailbox/mailbox" => 
          "webmail/mailboxes#create", :via => :post
        match "webmail/*mailbox/mailbox/new" => 
          "webmail/mailboxes#new", :via => :get
        match "webmail/*mailbox/mailbox/edit" => 
          "webmail/mailboxes#edit", :via => :get
        match "webmail/*mailbox/mailbox" => 
          "webmail/mailboxes#show", :via => :get
        match "webmail/*mailbox/mailbox" => 
          "webmail/mailboxes#update", :via => :patch
        match "webmail/*mailbox/mailbox" => 
          "webmail/mailboxes#destroy", :via => :delete
        resources "webmail_attachments",
          :controller => "webmail/mail_attachments",
          :path => "webmail_attachments"
        resources "webmail_sys_addresses",
          :controller => "webmail/sys_addresses",
          :path => "webmail_sys_addresses" do
            member do
              get :child_groups, :child_users, :create_mail
            end
            collection do
              post :mobile_manage
            end
          end
        resources "webmail_addresses",
          :controller => "webmail/addresses",
          :path => "webmail_addresses" do
            collection do
              get :import, :export
              post :candidate_import, :exec_import, :export
            end
            member do
              get :create_mail
            end
          end
        resources "webmail_address_groups",
          :controller => "webmail/address_groups",
          :path => "webmail_address_groups" do
            collection do
              post :create_mail, :mobile_manage
            end
          end
        resources "webmail_signs",
          :controller => "webmail/signs",
          :path => "webmail_signs"
        resources "webmail_filters",
          :controller => "webmail/filters",
          :path => "webmail_filters" do
            member do
              get :apply
              post :apply
            end
          end
        resources "webmail_templates", 
          :controller => "webmail/templates",
          :path => "webmail_templates"
        resources "webmail_memos", 
          :controller => "webmail/memos",
          :path => "webmail_memos"
        resources "webmail_tools", 
          :controller => "webmail/tools",
          :path => "webmail_tools" do
            collection do
              get :batch_delete
              post :batch_delete
            end
          end
        resources "webmail_settings",
          :controller => "webmail/settings",
          :path => "webmail/:category/settings"
        resources "webmail_docs",
          :controller => "webmail/docs",
          :path => "webmail/docs"
        namespace "webmail" do
          post "address_selector/parse_address" => "address_selector#parse_address"
          namespace "address_selector" do
            resources :sys_addresses, only: [:index, :show]
            resources :addresses, only: [:index, :show]
          end
        end
      end
    end
  end

  match "_admin/#{mod}/siteinfo" => "gw/admin/siteinfo#index", via: :get

  match "_admin/#{mod}" => "#{mod}/admin/webmail/mails#index",
    defaults: { mailbox: 'INBOX' }, via: :get

  match "_admin/#{mod}/webmail/tools/batch_delete(.:format)" => 
    "#{mod}/admin/webmail/tools#batch_delete", via: :get

  match "_admin/#{mod}/webmail_mobile_users(.:format)" => "#{mod}/admin/webmail/mobile#users", via: :get

  match "_api/#{mod}/webmail/unseen(.:format)" => "#{mod}/admin/webmail/api#unseen", via: :get
  match "_api/#{mod}/webmail/recent(.:format)" => "#{mod}/admin/webmail/api#recent", via: :get
end
