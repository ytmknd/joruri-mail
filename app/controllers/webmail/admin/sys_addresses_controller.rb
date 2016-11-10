class Webmail::Admin::SysAddressesController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Webmail::Admin::Mobile::Address
  layout 'admin/webmail/base'

  def pre_dispatch
    return redirect_to action: :index if params[:reset]
    @limit = 200
  end

  def index
    @root = Core.user_group.ancestors.first
    @parents = []
    @group   = @root
    @groups  = @group.enabled_children

    if params[:search]
      user = Sys::User.enabled_tenant_users.with_valid_email
      user = user.where(ldap: 1) if Sys::Group.show_only_ldap_user
      user = user.search(params)
      @users = user.order(Webmail::Setting.sys_address_orders).paginate(page: 1, per_page: @limit)
      @gid = params[:gid]
      @gname = "検索結果（#{params[:index]}）"
      return render :child_users, layout: false
    end
  end

  def show
    item = Sys::User.enabled_tenant_users.with_valid_email.where(id: params[:id])
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
    item = Sys::User.enabled_tenant_users.with_valid_email.where(id: ids)
    item = item.where(ldap: 1) if Sys::Group.show_only_ldap_user
    item.order(:email).map(&:email_format)
  end
end
