# encoding: utf-8
class Gw::Admin::Webmail::MemosController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"
  
  def index
    redirect_to url_for(:action => :show, :id => 0)
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
    
    _update @item, :location => url_for(:action => :show, :id => 0)
  end

protected

  def memo_body_item
    item = Gw::WebmailSetting.new
    item.and :user_id, Core.user.id
    item.and :name, :memo_body
    item.find(:first) || Gw::WebmailSetting.new(:name => 'memo_body', :value => '', :user_id => Core.user.id)
  end
end