class Gw::Admin::Webmail::SettingsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  def pre_dispatch
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    @categories = Gw::WebmailSetting.user_categorized_settings
    _index @categories
  end

  def show
    @item = Gw::WebmailSetting.user_setting(params[:id])
    _show @item
  end

  def new
    http_error(404)
  end

  def create
    http_error(404)
  end

  def update
    @item = Gw::WebmailSetting.user_setting(params[:id])
    @item.decoded_value = params[:item][:value]

    _update(@item)
  end

  def destroy
    http_error(404)
  end
end
