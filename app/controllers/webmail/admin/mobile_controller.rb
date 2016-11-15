class Webmail::Admin::MobileController < Webmail::Controller::Admin::Base
  around_action :set_ldap_scope

  def users
    @count = Sys::User.state_enabled.where(mobile_access: 1)
      .where.not(mobile_password: '').count

    render plain: "モバイル設定人数:#{@count}"
  end
end
