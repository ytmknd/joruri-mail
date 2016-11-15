class Webmail::Admin::AddressSelector::SysAddressesController < Webmail::Controller::Admin::Base
  around_action :set_ldap_scope

  def pre_dispatch
  end

  def index
    @items = Sys::User.state_enabled.with_valid_email.search(params)
      .order(Webmail::Setting.sys_address_orders)
      .paginate(page: 1, per_page: 200)
  end

  def show
    @group = Sys::Group.find(params[:id])
    @items = @group.users_having_email.reorder(Webmail::Setting.sys_address_orders)
  end
end
