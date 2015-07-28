# encoding: utf-8
class Gw::Admin::Webmail::TemplatesController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"
  
  def pre_dispatch
    #return error_auth unless Core.user.has_auth?(:designer)
  end
  
  def index
    item = Gw::WebmailTemplate.new.readable
    item.and :user_id, Core.user.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'name, id'
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Gw::WebmailTemplate.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Gw::WebmailTemplate.new({
      :default_flag => 0
    })
  end
  
  def create
    @item = Gw::WebmailTemplate.new(params[:item])
    @item.user_id = Core.user.id
    _create(@item)
  end
  
  def update
    @item = Gw::WebmailTemplate.new.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = params[:item]
    @item.user_id = Core.user.id
    
    _update(@item)
  end
  
  def destroy
    @item = Gw::WebmailTemplate.new.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item)
  end
end
