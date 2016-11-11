class Sys::Admin::LdapSynchrosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)

    Core.ldap.bind_as_master
    return render html: 'LDAPサーバーへの接続に失敗しました。', layout: true unless Core.ldap.connection
  end

  def index
    @items = Sys::LdapSynchroTask.order(version: :desc)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Sys::LdapSynchroTask.find_by!(version: params[:id])
    @items = @item.ldap_synchros.where(parent_id: 0, entry_type: 'group').order(:sort_no, :code)
    _show @items
  end

  def new
    @item = Sys::LdapSynchroTask.new
  end

  def create
    @item = Sys::LdapSynchroTask.new
    @item.version = Time.now.strftime('%s')
    @item.target_tenant_code = params[:tenant_code] if params[:tenant_code].present?

    begin
      @item.create_synchro
    rescue => e
      error_log e.backtrace.join("\n")
      error = e.message
    end

    if error.nil?
      flash[:notice] = "中間データを作成しました。"
      redirect_to url_for(action: :show, id: @item.version)
    else
      flash[:notice] = "中間データの作成に失敗しました。［ #{error} ］"
      redirect_to url_for(action: :index)
    end
  end

  def destroy
    @item = Sys::LdapSynchroTask.find_by!(version: params[:id])
    _destroy @item
  end

  def synchronize
    @item = Sys::LdapSynchroTask.find_by!(version: params[:id])

    begin
      @item.synchronize
    rescue => e
      error_log e.backtrace.join("\n")
      error = e.message
    end

    if error.nil?
      flash[:notice] = "同期処理が完了しました。"
    else
      flash[:notice] = "同期処理に失敗しました。［ #{error} ］"
    end

    redirect_to(action: :show)
  end
end
