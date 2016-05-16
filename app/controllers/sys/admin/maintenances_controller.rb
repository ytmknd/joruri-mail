class Sys::Admin::MaintenancesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
    @items = Sys::Maintenance.order(published_at: :desc).paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Sys::Maintenance.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Sys::Maintenance.new(state: 'public', published_at: Core.now)
  end

  def create
    @item = Sys::Maintenance.new(item_params)
    _create @item
  end

  def update
    @item = Sys::Maintenance.find(params[:id])
    @item.attributes = item_params
    _update @item
  end

  def destroy
    @item = Sys::Maintenance.find(params[:id])
    _destroy @item
  end

  private

  def item_params
    params.require(:item).permit(:state, :published_at, :title, :body)
  end
end
