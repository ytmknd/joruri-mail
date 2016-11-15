class Webmail::Admin::SysAddressesController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Webmail::Admin::Mobile::Address
  layout 'admin/webmail/base'

  around_action :set_ldap_scope

  def pre_dispatch
    return redirect_to action: :index if params[:reset]
    @limit = 200
  end

  def index
    @roots = Sys::Group.enabled_roots.order(:sort_no, :tenant_code)
    @groups = @roots.size == 1 ? @roots.first.enabled_children : @roots

    if params[:search]
      @users = Sys::User.state_enabled.with_valid_email.search(params)
        .order(Webmail::Setting.sys_address_orders)
        .paginate(page: 1, per_page: @limit)
      @gid = params[:gid]
      @gname = "検索結果（#{params[:index]}）"
      return render :child_users, layout: false
    end
  end

  def show
    @item = Sys::User.state_enabled.with_valid_email.find(params[:id])
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
    redirect_to new_webmail_mail_path('INBOX')
  end

  def create_mail
    to = ids_to_addrs(params[:id])
    flash[:mail_to] = to.join(', ')  if to.size  > 0
    redirect_to new_webmail_mail_path('INBOX')    
  end

  def child_groups
    @group = Sys::Group.find(params[:id])
    render layout: false if request.xhr?
  end

  def child_users
    @group = Sys::Group.find(params[:id])
    @users = @group.users_having_email.reorder(Webmail::Setting.sys_address_orders)
      .paginate(page: 1, per_page: 1000)
      .preload(:groups)
    @gid = @group.id
    @gname = @group.name
    render layout: false if request.xhr?
  end

  private

  def ids_to_addrs(ids)
    if ids.respond_to?(:keys)
      ids = ids.keys.uniq
    elsif ids.present?
      ids = [ids]
    else
      return []
    end
    Sys::User.state_enabled.with_valid_email.where(id: ids)
      .order(:email).map(&:email_format)
  end
end
