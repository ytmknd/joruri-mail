# encoding: utf-8
class Gw::Admin::Webmail::AddressGroupsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Gw::Controller::Admin::Mobile::Address
  layout "admin/gw/webmail"
  helper Gw::AddressHelper
    
  def pre_dispatch
    
    return redirect_to :action => :index if params[:reset]
    
    #return error_auth unless Core.user.has_auth?(:designer)
    parent_id = params[:parent_id]
    parent_id = params[:item][:parent_id] if params[:item]
    unless parent_id.blank?
      parent = Gw::WebmailAddressGroup.new
      parent.and :id, parent_id
      parent.and :user_id, Core.user.id
      @parent = parent.find(:first)
      return error_auth if @parent && !@parent.readable?
    end
    
    @limit = 200
    
    if [:index, :show, :child_items].include? params[:action].to_sym
      @order = Gw::WebmailSetting.user_config_value(:address_order)
    end
  end
  
  def index
    item = Gw::WebmailAddress.new.readable
    item.and :user_id, Core.user.id
    #item.page 1, @limit
    item.order get_order()
    @items = item.find(:all)
    
    if params[:search]
      item = Gw::WebmailAddress.new.readable
      item.search params if params[:search]
      item.and :user_id, Core.user.id
      #item.page 1, @limit
      item.order get_order()
      @s_items = item.find(:all)
    end

    @groups = Gw::WebmailAddressGroup.user_groups
    @root_groups = @groups.select {|i| i.parent_id == 0}      

    respond_to do |format|
      format.html { }
      format.xml  { @items = @s_items if params[:search] }
    end

    #_index @groups
  end
  
  def show
    return show_all if params[:id] == '0'
    
    @item = Gw::WebmailAddressGroup.new.find(params[:id])
    return error_auth unless @item.readable?
    @parent = @item
    
    @items = @item.addresses.find(:all, :order => get_order())
    
    respond_to do |format|
      format.html { }
      format.xml  { }
      format.js   { }
    end
    
    #_show @item
  end
  
  def show_all
    @item = Gw::WebmailAddressGroup.new(:name => "すべて")
    
    item = Gw::WebmailAddress.new.readable
    item.and   :user_id, Core.user.id
    #item.page  params[:page], params[:limit]
    item.order get_order()
    @items = item.find(:all)
  end

  def new
    @item = Gw::WebmailAddressGroup.new({
      :parent_id => @parent ? @parent.id : 0
    })
  end
  
  def create
    @item = Gw::WebmailAddressGroup.new(params[:item])
    @item.user_id = Core.user.id
    @item.parent_id = @parent ? @parent.id : 0
    @item.level_no  = @parent ? @parent.level_no + 1 : 1
    @item.call_update_child_level_no = true

    _create @item
  end
  
  def update
    @item = Gw::WebmailAddressGroup.new.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = params[:item]
    @item.user_id   = Core.user.id
    @item.parent_id = @parent ? @parent.id : 0
    @item.level_no  = @parent ? @parent.level_no + 1 : 1
    @item.call_update_child_level_no = true
    
    _update @item
  end
  
  def destroy
    @item = Gw::WebmailAddressGroup.new.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy @item
  end

  def create_mail
    to = ids_to_addrs(params[:to])
    cc = ids_to_addrs(params[:cc])
    bcc = ids_to_addrs(params[:bcc])
    flash[:mail_to]  = to.join(', ')  if to.size  > 0
    flash[:mail_cc]  = cc.join(', ')  if cc.size  > 0
    flash[:mail_bcc] = bcc.join(', ') if bcc.size > 0
    redirect_to new_gw_webmail_mail_path('INBOX')
  end
  
  def child_items
    @item = Gw::WebmailAddressGroup.new.find(params[:id])
    return error_auth unless @item.readable?
    
    @groups = @item.children
    @items = @item.addresses.find(:all, :order => get_order())
    
    respond_to do |format|
      format.xml  { }
    end        
  end
  
protected
  
  def ids_to_addrs(ids)
    return [] if ids.blank? || !ids.is_a?(Hash)
    item = Gw::WebmailAddress.new
    item.and :user_id, Core.user.id
    item.and :id, 'IN', ids.keys
    item.and :email, 'IS NOT', nil
    item.and :email, '!=', ''
    item.find(:all, :order => :kana).collect {|u| %Q(#{u.name} <#{u.email}>) }
  end
  
  def get_order
    rslt = @order.blank? ? 'email' : @order
    rslt << ', id'
  end
end
