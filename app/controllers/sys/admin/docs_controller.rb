class Sys::Admin::DocsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
    @items = Webmail::Doc.order(:sort_no, :id).paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Webmail::Doc.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Webmail::Doc.new(
      state: 'public',
      sort_no: 0,
      published_at: Core.now,
    )
  end

  def create
    @item = Webmail::Doc.new(item_params)

    _create @item
  end

  def update
    @item = Webmail::Doc.find(params[:id])
    @item.attributes = item_params

    _update @item
  end

  def destroy
    @item = Webmail::Doc.find(params[:id])

    _destroy @item
  end

  private

  def item_params
    params.require(:item).permit(:state, :published_at, :sort_no, :title, :body)
  end
end
