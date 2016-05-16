class Sys::Admin::ProductSynchrosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
    @version = params[:version_id] || nil
  end

  def index
    id = params[:p_id] == '0' ? 1 : params[:p_id]
    if @version.blank?
      @groups = System::Group.where(parent_id: 0).order(:sort_no, :code, :id)
    else
      @groups = System::LdapTemporary.where(version: @version, parent_id: 0, data_type: 'group')
        .order(:sort_no, :code, :id)
    end
    #_index @items
  end

  def synchronize
    @version = params[:version_id]
    if @version.blank?
      @items = System::Group.where(state: 'enabled', ldap: 1, parent_id: 1, end_at: nil).order(:sort_no, :code)
    else
      @items = System::LdapTemporary.where(version: @version, parent_id: 0, data_type: 'group')
        .order(:sort_no, :code)
    end

    unless parent = Sys::Group.find_by(parent_id: 0)
      return render inline: "グループのRootが見つかりません。", layout: true
    end

    Sys::Group.update_all(ldap_version: nil)
    Sys::User.update_all(ldap_version: nil)

    @results = { group: 0, gerr: 0, user: 0, uerr: 0 }
    @items.each { |group| do_synchro(group, parent) }

    @results[:udel] = Sys::User.where(ldap: 1, ldap_version: nil).destroy_all.size
    @results[:gdel] = Sys::Group.where(parent_id: 0, ldap: 1, ldap_version: nil).destroy_all.size

    messages = ["同期処理が完了しました。<br />"]
    messages << "グループ"
    messages << "-- 更新 #{@results[:group]}件"
    messages << "-- 削除 #{@results[:gdel]}件" if @results[:gdel] > 0
    messages << "-- 失敗 #{@results[:gerr]}件" if @results[:gerr] > 0
    messages << "ユーザ"
    messages << "-- 更新 #{@results[:user]}件"
    messages << "-- 削除 #{@results[:udel]}件" if @results[:udel] > 0
    messages << "-- 失敗 #{@results[:uerr]}件" if @results[:uerr] > 0

    flash[:notice] = messages.join('<br />').html_safe
    redirect_to action: :index, version_id: @version
  end

  private

  def do_synchro(group, parent = nil)
    ## group
    sg                = Sys::Group.where(code: group.code).first_or_initialize
    sg.code           = group.code
    sg.parent_id      = parent.id
    sg.state        ||= 'enabled'
    sg.web_state    ||= 'public'
    sg.name           = group.name
    sg.name_en        = group.name_en if !group.name_en.blank?
    sg.email          = group.email if !group.email.blank?
    sg.level_no       = parent.level_no + 1
    sg.sort_no        = group.sort_no
    sg.group_s_name   = group.group_s_name
    sg.ldap         ||= 1
    sg.ldap_version   = @version.blank? ? group.ldap_version : @version
    
    if sg.ldap == 1
      if sg.save(validate: false)
        @results[:group] += 1
      else
        @results[:gerr] += 1
        return false
      end
    end

    ## users
    group.ldap_users.each do |user|
      su                   = Sys::User.where(account: user.code).first_or_initialize
      su.account           = user.code
      su.state           ||= 'enabled'
      su.auth_no         ||= 2
      su.name              = user.name
      su.name_en           = user.name_en
      su.email             = user.email
      su.kana              = user.kana
      su.ldap            ||= 1
      su.ldap_version      = @version.blank? ? user.ldap_version : @version
      su.sort_no           = user.sort_no
      su.official_position = user.official_position
      su.assigned_job      = user.assigned_job
      su.group_s_name      = user.group_s_name
      su.mobile_access     = user.mobile_access if @version.blank?
      su.mobile_password   = user.mobile_password if @version.blank?
      su.in_group_id       = sg.id

      if su.ldap == 1
        if su.save
          @results[:user] += 1
        else
          @results[:uerr] += 1
        end
      end
    end

    ## next
    group.ldap_children.each { |g| do_synchro(g, sg) }
  end
end