# encoding: utf-8
class Gw::Admin::Webmail::DocsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"
  
  def pre_dispatch
    
  end
  
  def index
    item = Gw::WebmailDoc.new.public
    item.order 'sort_no, id'
    item.page params[:page], params[:limit]
    @items = item.find(:all)  
    
    _index @items
  end
  
  def show
    @item = Gw::WebmailDoc.find_by_id(params[:id])
    return http_error(404) unless @item
    return error_auth unless @item.readable?
    
    _show @item
  end
  
end