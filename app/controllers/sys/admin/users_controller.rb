# encoding: utf-8
class Sys::Admin::UsersController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  
  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end
  
  def index
    @item = Sys::User.new # for search
    @item.in_group_id = params[:s_group_id]
    
    item = Sys::User.new
    item.search params
    item.page  params[:page], params[:limit]
    item.order "LPAD(account, 15, '0')"
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Sys::User.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Sys::User.new({
      :state       => 'enabled',
      :ldap        => '0',
      :auth_no     => 2
    })
  end
  
  def create
    @item = Sys::User.new(params[:item])
    _create(@item)
  end
  
  def update
    @item = Sys::User.new.find(params[:id])
    @item.attributes = params[:item]
    _update(@item)
  end
  
  def destroy
    @item = Sys::User.new.find(params[:id])
    _destroy(@item)
  end
end
