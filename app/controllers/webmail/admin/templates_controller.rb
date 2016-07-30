class Webmail::Admin::TemplatesController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  def pre_dispatch
  end

  def index
    @items = Webmail::Template.readable.where(user_id: Core.user.id).order(:name, :id)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Webmail::Template.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Webmail::Template.new(default_flag: 0)
  end

  def create
    @item = Webmail::Template.new(item_params)
    @item.user_id = Core.user.id
    _create(@item)
  end

  def update
    @item = Webmail::Template.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id = Core.user.id

    _update(@item)
  end

  def destroy
    @item = Webmail::Template.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item)
  end

  private

  def item_params
    params.require(:item).permit(:name, :to, :cc, :bcc, :subject, :body, :default_flag)
  end
end
