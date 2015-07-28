# coding: utf-8
class Gw::Admin::Webmail::MobileController < Gw::Controller::Admin::Base
  
  def users
    cond = Condition.new
    cond.and :state, 'enabled'
    cond.and :ldap, 1
    cond.and :mobile_access, 1
    cond.and :mobile_password, '!=', ''
    @count = Sys::User.find(:all, :conditions => cond.where).count
    
    render :text => "モバイル設定人数:#{@count}"
  end
end