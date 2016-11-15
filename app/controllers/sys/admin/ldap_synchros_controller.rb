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
    @items = @item.ldap_synchros.where(parent_id: 0, entry_type: 'group')
      .order(:sort_no, :code)
      .preload_children_and_users
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
      results = @item.fetch_results
      messages = ["中間データを作成しました。"]
      messages << "グループ #{results[:group]}件"
      messages << "-- 失敗 #{results[:gerr]}件" if results[:gerr] > 0
      messages << "ユーザー #{results[:user]}件"
      messages << "-- 失敗 #{results[:uerr]}件" if results[:uerr] > 0
      flash[:notice] = messages.join('<br />').html_safe
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
      results = @item.synchro_results
      messages = ["同期処理が完了しました。"]
      messages << "グループ"
      messages << "-- 更新 #{results[:group]}件"
      messages << "-- 削除 #{results[:gdel]}件" if results[:gdel] > 0
      messages << "-- 失敗 #{results[:gerr]}件" if results[:gerr] > 0
      messages << "ユーザー"
      messages << "-- 更新 #{results[:user]}件"
      messages << "-- 削除 #{results[:udel]}件" if results[:udel] > 0
      messages << "-- 失敗 #{results[:uerr]}件" if results[:uerr] > 0
      flash[:notice] = messages.join('<br />').html_safe
    else
      flash[:notice] = "同期処理に失敗しました。［ #{error} ］"
    end

    redirect_to(action: :show)
  end
end
