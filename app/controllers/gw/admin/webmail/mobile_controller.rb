# coding: utf-8
class Gw::Admin::Webmail::MobileController < Gw::Controller::Admin::Base
  
  def users
    @count = Sys::User.where(state: 'enabled', ldap: 1, mobile_access: 1)
      .where.not(mobile_password: '').count

    render text: "モバイル設定人数:#{@count}"
  end
end