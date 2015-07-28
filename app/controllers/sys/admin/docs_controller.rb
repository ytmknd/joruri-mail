# encoding: utf-8
class Sys::Admin::DocsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  
  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end
  
  def index
    item = Gw::WebmailDoc.new
    item.page  params[:page], params[:limit]
    item.order 'sort_no, id'
    @items = item.find(:all)
    
    _index @items
  end
  
  def show
    @item = Gw::WebmailDoc.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Gw::WebmailDoc.new({
      :state        => 'public',
      :sort_no      => 0,
      :published_at => Core.now,
    })
  end
  
  def create
    @item = Gw::WebmailDoc.new(params[:item])
    
    _create @item
  end
  
  def update
    @item = Gw::WebmailDoc.new.find(params[:id])
    @item.attributes = params[:item]
    
    _update @item
  end
  
  def destroy
    @item = Gw::WebmailDoc.new.find(params[:id])
    
    _destroy @item
  end
end
