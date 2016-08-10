class Webmail::Admin::SignsController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  def pre_dispatch
  end

  def index
    @items = Webmail::Sign.where(user_id: Core.user.id).order(:name, :id)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Webmail::Sign.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Webmail::Sign.new(default_flag: 0)
  end

  def create
    @item = Webmail::Sign.new(item_params)
    @item.user_id = Core.user.id
    _create(@item)
  end

  def update
    @item = Webmail::Sign.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id = Core.user.id

    _update(@item)
  end

  def destroy
    @item = Webmail::Sign.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item)
  end

  private

  def item_params
    params.require(:item).permit(:name, :body, :default_flag)
  end
end
