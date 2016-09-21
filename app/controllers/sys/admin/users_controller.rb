class Sys::Admin::UsersController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
    return redirect_to action: :index if params[:reset]
  end

  def index
    @items = Sys::User.search(params).order("LPAD(account, 15, '0')")
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Sys::User.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Sys::User.new(
      state: 'enabled',
      ldap: '0',
      auth_no: 2
    )
  end

  def create
    @item = Sys::User.new(item_params)
    _create(@item)
  end

  def update
    @item = Sys::User.find(params[:id])
    @item.attributes = item_params
    _update(@item)
  end

  def destroy
    @item = Sys::User.find(params[:id])
    _destroy(@item)
  end

  private

  def item_params
    params.require(:item).permit(:in_group_id, :account, :name, :kana, :name_en, :email, :sort_no,
      :official_position, :assigned_job, :state, :auth_no, :ldap, :password, :mobile_access, :mobile_password)
  end
end
