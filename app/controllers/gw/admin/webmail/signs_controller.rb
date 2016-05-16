class Gw::Admin::Webmail::SignsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  def pre_dispatch
    #return error_auth unless Core.user.has_auth?(:designer)
  end

  def index
    @items = Gw::WebmailSign.readable.where(user_id: Core.user.id).order(:name, :id)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Gw::WebmailSign.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Gw::WebmailSign.new(default_flag: 0)
  end

  def create
    @item = Gw::WebmailSign.new(item_params)
    @item.user_id = Core.user.id
    _create(@item)
  end

  def update
    @item = Gw::WebmailSign.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id = Core.user.id

    _update(@item)
  end

  def destroy
    @item = Gw::WebmailSign.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item)
  end

  private

  def item_params
    params.require(:item).permit(:name, :body, :default_flag)
  end
end
