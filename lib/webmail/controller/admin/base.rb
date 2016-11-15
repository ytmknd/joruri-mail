class Webmail::Controller::Admin::Base < Sys::Controller::Admin::Base
  layout  'admin/webmail'

  around_action :set_tenant_scope

  def initialize_application
    return false unless super

    Core.switch_users = Webmail::Setting.load_switch_users
    Core.current_user = Core.user

    if (account = params[:current_account] || session[:current_account])
      if current_user = Core.switch_users.find{|x| x.account == account}
        Core.current_user = current_user
        session[:current_account] = current_user.account
      end
    end

    if Core.user.account != Core.current_user.account
      unless Sys::User.authenticate(current_user.account, current_user.password)
        raise %Q(認証に失敗しました。切替ユーザーのアカウント設定を確認してください。<br />) +  
          %Q(<a href="/?current_account=#{Core.user.account}">ログインアカウントに戻る</a><br />)
      end
    end
  end

  private

  def set_tenant_scope
    tenant_codes = Core.user.groups.map(&:tenant_code)
    Sys::Group.in_tenant(tenant_codes).scoping do
      Sys::User.in_tenant(tenant_codes).scoping do
        yield
      end
    end
  end

  def set_ldap_scope
    if Joruri.config.application['webmail.show_only_ldap_user'] == 1
      Sys::User.where(ldap: 1).scoping do
        yield
      end
    else
      yield
    end
  end
end
