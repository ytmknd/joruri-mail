class Gw::Admin::Webmail::SettingsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  helper Gw::MailHelper
  layout "admin/gw/webmail"

  def pre_dispatch
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    @categories = Gw::WebmailSetting.user_categorized_configs
    _index @categories
  end

  def show
    @item = Gw::WebmailSetting.user_config(params[:id])
    _show @item
  end

  def new
    http_error(404)
  end

  def create
    http_error(404)
  end

  def update
    @item = Gw::WebmailSetting.user_config(params[:id])
    @item.set_value(params)

    _update(@item) do
      if Joruri.config.application['webmail.synchronize_mobile_setting'] == 1
        synchronize_mobile_setting(@item)
      end
    end
  end

  def destroy
    http_error(404)
  end

  private

  def synchronize_mobile_setting(item)
    case item.name.intern
    when :mobile_access, :mobile_password
      user = System::User.where(code: Core.user.account).first
      if user && !Gw::WebmailSetting.save_mobile_setting_for_user(user, item)
        flash[:notice] = "グループウェアの同期処理に失敗しました。"
      end
    end
  end
end
