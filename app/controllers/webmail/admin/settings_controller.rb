class Webmail::Admin::SettingsController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  def pre_dispatch
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    @categories = Webmail::Setting.user_categorized_settings
    _index @categories
  end

  def show
    @item = Webmail::Setting.user_setting(params[:id])
    _show @item
  end

  def new
    http_error(404)
  end

  def create
    http_error(404)
  end

  def update
    @item = Webmail::Setting.user_setting(params[:id])
    @item.decoded_value = params[:item][:value]

    _update(@item)
  end

  def destroy
    http_error(404)
  end
end
