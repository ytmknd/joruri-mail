class Gw::Admin::Webmail::SysAddressesController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Gw::Controller::Admin::Mobile::Address
  helper Gw::MailHelper
  layout "admin/gw/webmail"

  def pre_dispatch
    return redirect_to action: :index if params[:reset]
    @limit = 200
    @orders = Gw::WebmailSetting.load_sys_address_orders
  end

  def index
    @root = Sys::Group.find(1)

    @parents = []
    @group   = @root
    @groups  = @group.enabled_children

    if params[:search]
      user = Sys::User.includes(:groups).where(state: 'enabled').with_valid_email
      user = user.where(ldap: 1) if Sys::Group.show_only_ldap_user
      user = user.search(params)
      @users = user.order(@orders).paginate(page: 1, per_page: @limit)
      @gid = params[:gid]
      @gname = "検索結果（#{params[:index]}）"
      return render :child_users, layout: false
    end
  end

  def show
    item = Sys::User.state_enabled.where(id: params[:id])
    item = item.where(ldap: 1) if Sys::Group.show_only_ldap_user
    @item = item.first
    return http_error(404) if @item.blank? || @item.email.blank?

    render layout: false if request.xhr?
  end

  ## post/create mail
  def create
    to = ids_to_addrs(params[:to])
    cc = ids_to_addrs(params[:cc])
    bcc = ids_to_addrs(params[:bcc])
    flash[:mail_to]  = to.join(', ')  if to.size  > 0
    flash[:mail_cc]  = cc.join(', ')  if cc.size  > 0
    flash[:mail_bcc] = bcc.join(', ') if bcc.size > 0
    redirect_to new_gw_webmail_mail_path('INBOX')
  end

  def create_mail
    to = ids_to_addrs(params[:id])
    flash[:mail_to] = to.join(', ')  if to.size  > 0
    redirect_to new_gw_webmail_mail_path('INBOX')    
  end

  def child_groups
    @group = Sys::Group.find(params[:id])
    @children = @group.enabled_children
    render layout: false if request.xhr?
  end

  def child_users
    @group = Sys::Group.find(params[:id])
    @users = @group.users_having_email.reorder(@orders).paginate(page: 1, per_page: 1000)
    @gid = @group.id
    @gname = @group.name
    render layout: false if request.xhr?
  end

  private

  def ids_to_addrs(ids)
    if ids.is_a?(Hash)
      ids = ids.keys.uniq
    elsif ids.is_a?(String) && ids.present?
      ids = [ids]
    else
      return []
    end
    item = Sys::User.where(id: ids, state: 'enabled').with_valid_email
    item = item.where(ldap: 1) if Sys::Group.show_only_ldap_user
    item.order(:email).map(&:email_format)
  end
end
