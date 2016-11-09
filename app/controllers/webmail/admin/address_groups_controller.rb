class Webmail::Admin::AddressGroupsController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Webmail::Admin::Mobile::Address
  layout 'admin/webmail/base'

  def pre_dispatch
    return redirect_to action: :index if params[:reset]

    #return error_auth unless Core.user.has_auth?(:designer)
    parent_id = params[:parent_id]
    parent_id = params[:item][:parent_id] if params[:item]
    if parent_id.present?
      @parent = Webmail::AddressGroup.where(id: parent_id, user_id: Core.user.id).first
      return error_auth if @parent && !@parent.readable?
    end

    @limit = 200
  end

  def index
    @items = Webmail::Address.where(user_id: Core.user.id).order(Webmail::Setting.address_orders)
    @s_items = @items.search(params) if params[:search]

    @root_groups = Webmail::AddressGroup.user_root_groups.preload_children

    _index @s_items || @items
  end

  def show
    @item = Webmail::AddressGroup.find(params[:id])
    return error_auth unless @item.readable?

    @addresses = @item.addresses.order(Webmail::Setting.address_orders)

    render layout: false if request.xhr?
  end

  def new
    @item = Webmail::AddressGroup.new(
      parent_id: @parent ? @parent.id : 0
    )
  end

  def create
    @item = Webmail::AddressGroup.new(item_params)
    @item.user_id = Core.user.id
    @item.parent_id = @parent ? @parent.id : 0
    @item.level_no  = @parent ? @parent.level_no + 1 : 1
    @item.call_update_child_level_no = true

    _create @item
  end

  def update
    @item = Webmail::AddressGroup.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id   = Core.user.id
    @item.parent_id = @parent ? @parent.id : 0
    @item.level_no  = @parent ? @parent.level_no + 1 : 1
    @item.call_update_child_level_no = true

    _update @item
  end

  def destroy
    @item = Webmail::AddressGroup.find(params[:id])
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
    redirect_to new_webmail_mail_path('INBOX')
  end

  private

  def item_params
    params.require(:item).permit(:parent_id, :name)
  end

  def ids_to_addrs(ids)
    return [] if ids.blank?
    Webmail::Address.where(user_id: Core.user.id, id: ids.keys)
      .where.not(email: nil).where.not(email: '').order(:kana)
      .map(&:email_format)
  end
end
