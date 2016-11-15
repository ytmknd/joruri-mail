class Sys::Admin::LdapGroupsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  
  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)

    params[:parent] = Core.ldap.config[:base] if params[:parent] == '0'

    Core.ldap.bind_as_master

    begin
      @entry = Core.ldap.entry.find_by_dn(params[:parent])
    rescue RuntimeError => e
      error = e.message
    end
    return render html: "LDAP検索に失敗しました。#{error}", layout: true unless @entry
  end

  def index
    @parents = @entry.parents
    @children = @entry.children.reject(&:user_object?)
    @users = @entry.users
  end
end
