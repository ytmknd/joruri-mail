class Gw::Admin::Webmail::MemosController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  def index
    redirect_to url_for(action: :show, id: 0)
  end

  def show
    @item = memo_body_item
    _show @item
  end

  def edit
    @item = memo_body_item
  end

  def update
    @item = memo_body_item
    @item.value = params[:memo_body]
    @item.user_id = Core.user.id

    _update @item, location: url_for(action: :show, id: 0)
  end

  private

  def memo_body_item
    Gw::WebmailSetting.where(user_id: Core.user.id, name: 'memo_body').first_or_initialize(value: '')
  end
end
