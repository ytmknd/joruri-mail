require 'csv'
class Sys::Admin::Groups::ExportController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
  end

  def export
    if params[:do] == 'groups'
      export_groups
    elsif params[:do] == 'users'
      export_users
    else
      return redirect_to(action: :index)
    end
  end

  private

  def export_groups
    data = CSV.generate do |csv|
      csv << [
        :code, :parent_code, :state, :web_state, :level_no, :sort_no,
        :layout_id, :ldap, :ldap_version, :name, :name_en, :tel, :outline_uri, :email
      ]
      all_groups = Sys::Group.roots.map(&:descendants).flatten.reject(&:root?)
      all_groups.each do |group|
        row = []
        row << group.code
        row << group.parent.code
        row << group.state
        row << group.web_state
        row << group.level_no
        row << group.sort_no
        row << group.layout_id
        row << group.ldap
        row << group.ldap_version
        row << group.name
        row << group.name_en
        row << group.tel
        row << group.outline_uri
        row << group.email
        csv << row
      end
    end

    data = NKF.nkf('-Ws -Lw', data)
    send_data(data, type: 'text/csv; charset=Shift_JIS', filename: "sys_groups_#{Time.now.to_i}.csv")
  end

  def export_users
    data = CSV.generate do |csv|
      csv << [
        :account, :state, :name, :name_en, :email, :auth_no, :password, :ldap, :ldap_version, :group_code
      ]
      Sys::User.order(:id).each do |user|
        next unless user.groups[0]
        row = []
        row << user.account
        row << user.state
        row << user.name
        row << user.name_en
        row << user.email
        row << user.auth_no
        row << user.password
        row << user.ldap
        row << user.ldap_version
        row << user.groups[0].code
        csv << row
      end
    end

    data = NKF.nkf('-Ws -Lw', data)
    send_data(data, type: 'text/csv; charset=Shift_JIS', filename: "sys_users_#{Time.now.to_i}.csv")
  end
end
