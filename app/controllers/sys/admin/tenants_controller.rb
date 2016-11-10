class Sys::Admin::TenantsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
    @items = Sys::Tenant.order(:code).paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Sys::Tenant.find(params[:id])
    return error_auth unless @item.readable?
    _show @item
  end

  def new
    @item = Sys::Tenant.new(
      default_pass_limit: 'disabled',
      mobile_access: 0
    )
  end

  def create
    @item = Sys::Tenant.new(item_params)
    _create @item
  end

  def update
    @item = Sys::Tenant.find(params[:id])
    @item.attributes = item_params
    _update @item
  end

  def destroy
    @item = Sys::Tenant.find(params[:id])
    _destroy @item
  end

  private

  def item_params
    params.require(:item).permit(
      :code, :name, :mail_domain, :default_pass_limit, :default_pass_prefix, :mobile_access
    )
  end
end
