class Webmail::Controller::Admin::Base < Sys::Controller::Admin::Base
  layout  'admin/webmail'

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
end
