class Sys::Admin::GroupUsersController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  
  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)

    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = Sys::Group.find(id)
  end

  def index
    redirect_to(sys_groups_path(@parent))
  end

  def show
    @item = Sys::User.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Sys::User.new(
      state: 'enabled',
      ldap: 0,
      auth_no: 2,
      in_group_id: @parent.id
    )
  end

  def create
    @item = Sys::User.new(item_params)
    _create(@item, location: sys_groups_path(@parent))
  end

  def update
    @item = Sys::User.find(params[:id])
    @item.attributes = item_params
    _update(@item, location: sys_groups_path(@parent))
  end

  def destroy
    @item = Sys::User.find(params[:id])
    _destroy(@item, location: sys_groups_path(@parent))
  end

  private

  def item_params
    params.require(:item).permit(
      :in_group_id, :account, :name, :kana, :name_en, :email, :sort_no,
      :official_position, :assigned_job, :state, :auth_no, :ldap, :password, :mobile_access, :mobile_password
    )
  end
end
