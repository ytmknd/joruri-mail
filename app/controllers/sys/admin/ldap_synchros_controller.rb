class Sys::Admin::LdapSynchrosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
    return render(text: "LDAPサーバーに接続できません。", layout: true) unless Core.ldap.connection
  end

  def index
    @items = Sys::LdapSynchro.group(:version).order(version: :desc)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @version = params[:id]
    @items = Sys::LdapSynchro.where(version: @version, parent_id: 0, entry_type: 'group')
      .order(:sort_no, :code)

    _show @items
  end

  def new
    @item = Sys::LdapSynchro.new
  end

  def create
    @version = Time.now.strftime('%s')
    error = nil

    begin
      @results = Sys::LdapSynchro.create_synchro(@version)
    rescue => e
      error = e.message
    end

    if error.nil?
      messages = ["中間データを作成しました。<br />"]
      messages << "グループ #{@results[:group]}件"
      messages << "-- 失敗 #{@results[:gerr]}件" if @results[:gerr] > 0
      messages << "ユーザー #{@results[:user]}件"
      messages << "-- 失敗 #{@results[:uerr]}件" if @results[:uerr] > 0
      flash[:notice] = messages.join('<br />').html_safe
      redirect_to url_for(action: :show, id: @version)
    else
      flash[:notice] = "中間データの作成に失敗しました。［ #{error} ］"
      redirect_to url_for(action: :index)
    end
  end

  def update
  end

  def destroy
    Sys::LdapSynchro.where(version: params[:id]).delete_all
    flash[:notice] = "削除処理が完了しました。"
    redirect_to url_for(action: :index)
  end

  def synchronize
    @version = params[:id]
    error = nil

    begin
      @results = Sys::LdapSynchro.synchronize(@version)
    rescue => e
      error = e.message
    end

    if error.nil?
      messages = ["同期処理が完了しました。<br />"]
      messages << "グループ"
      messages << "-- 更新 #{@results[:group]}件"
      messages << "-- 削除 #{@results[:gdel]}件" if @results[:gdel] > 0
      messages << "-- 失敗 #{@results[:gerr]}件" if @results[:gerr] > 0
      messages << "ユーザー"
      messages << "-- 更新 #{@results[:user]}件"
      messages << "-- 削除 #{@results[:udel]}件" if @results[:udel] > 0
      messages << "-- 失敗 #{@results[:uerr]}件" if @results[:uerr] > 0
      flash[:notice] = messages.join('<br />').html_safe
    else
      flash[:notice] = "同期処理に失敗しました。［ #{error} ］"
    end

    redirect_to(action: :index)
  end
end
