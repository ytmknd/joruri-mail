class Gw::Admin::Webmail::AddressGroupsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Gw::Controller::Admin::Mobile::Address
  layout "admin/gw/webmail"
  helper Gw::AddressHelper

  def pre_dispatch
    return redirect_to action: :index if params[:reset]

    #return error_auth unless Core.user.has_auth?(:designer)
    parent_id = params[:parent_id]
    parent_id = params[:item][:parent_id] if params[:item]
    if parent_id.present?
      @parent = Gw::WebmailAddressGroup.where(id: parent_id, user_id: Core.user.id).first
      return error_auth if @parent && !@parent.readable?
    end

    @limit = 200

    if [:index, :show, :child_items].include? params[:action].to_sym
      @order = Gw::WebmailSetting.user_config_value(:address_order)
    end
  end

  def index
    @items = Gw::WebmailAddress.readable.where(user_id: Core.user.id).order(get_order())

    if params[:search]
      item = Gw::WebmailAddress.readable.where(user_id: Core.user.id).order(get_order())
      item = item.search(params) if params[:search]
      @s_items = item
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

    @item = Gw::WebmailAddressGroup.find(params[:id])
    return error_auth unless @item.readable?
    @parent = @item

    @items = @item.addresses.order(get_order())

    respond_to do |format|
      format.html { }
      format.xml  { }
      format.js   { }
    end

    #_show @item
  end

  def show_all
    @item = Gw::WebmailAddressGroup.new(name: "すべて")
    @items = Gw::WebmailAddress.readable.where(user_id: Core.user.id).order(get_order())
  end

  def new
    @item = Gw::WebmailAddressGroup.new(
      parent_id: @parent ? @parent.id : 0
    )
  end

  def create
    @item = Gw::WebmailAddressGroup.new(item_params)
    @item.user_id = Core.user.id
    @item.parent_id = @parent ? @parent.id : 0
    @item.level_no  = @parent ? @parent.level_no + 1 : 1
    @item.call_update_child_level_no = true

    _create @item
  end

  def update
    @item = Gw::WebmailAddressGroup.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id   = Core.user.id
    @item.parent_id = @parent ? @parent.id : 0
    @item.level_no  = @parent ? @parent.level_no + 1 : 1
    @item.call_update_child_level_no = true

    _update @item
  end

  def destroy
    @item = Gw::WebmailAddressGroup.find(params[:id])
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
    @item = Gw::WebmailAddressGroup.find(params[:id])
    return error_auth unless @item.readable?

    @groups = @item.children
    @items = @item.addresses.order(get_order())

    respond_to do |format|
      format.xml  { }
    end        
  end

  private

  def item_params
    params.require(:item).permit(:name, :body, :default_flag)
  end

  def ids_to_addrs(ids)
    return [] if ids.blank? || !ids.is_a?(Hash)
    Gw::WebmailAddress.where(user_id: Core.user.id, id: ids.keys)
      .where.not(email: nil).where.not(email: '').order(:kana)
      .map {|u| %Q(#{u.name} <#{u.email}>) }
  end

  def get_order
    rslt = (@order.presence || 'email')
    rslt << ', id'
  end
end
