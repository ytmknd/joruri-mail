class Webmail::Admin::MobileController < Webmail::Controller::Admin::Base
  def users
    @count = Sys::User.enabled_tenant_users.where(ldap: 1, mobile_access: 1)
      .where.not(mobile_password: '').count

    render plain: "モバイル設定人数:#{@count}"
  end
end
