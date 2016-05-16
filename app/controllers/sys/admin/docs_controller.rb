class Sys::Admin::DocsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
    @items = Gw::WebmailDoc.order(:sort_no, :id).paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Gw::WebmailDoc.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Gw::WebmailDoc.new(
      state: 'public',
      sort_no: 0,
      published_at: Core.now,
    )
  end

  def create
    @item = Gw::WebmailDoc.new(item_params)

    _create @item
  end

  def update
    @item = Gw::WebmailDoc.find(params[:id])
    @item.attributes = item_params

    _update @item
  end

  def destroy
    @item = Gw::WebmailDoc.find(params[:id])

    _destroy @item
  end

  private

  def item_params
    params.require(:item).permit(:state, :published_at, :sort_no, :title, :body)
  end
end
