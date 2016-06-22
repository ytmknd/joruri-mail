class Gw::Admin::Webmail::AddressSelector::SysAddressesController < Gw::Controller::Admin::Base
  def pre_dispatch
    @orders = Gw::WebmailSetting.load_sys_address_orders
  end

  def index
    item = Sys::User.includes(:groups).where(state: 'enabled').with_valid_email
    item = item.where(ldap: 1) if Sys::Group.show_only_ldap_user
    @items = item.search(params)
      .order(@orders)
      .paginate(page: 1, per_page: 200)
  end

  def show
    @group = Sys::Group.find(params[:id])
    @groups = @group.enabled_children
    @items = @group.users_having_email.reorder(@orders)
  end
end
