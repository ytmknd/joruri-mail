class Gw::Admin::Webmail::AddressSelector::AddressesController < Gw::Controller::Admin::Base
  def pre_dispatch
    @orders = Gw::WebmailSetting.load_address_orders
  end

  def index
    @items = Gw::WebmailAddress.where(user_id: Core.user.id)
      .search(params)
      .order(@orders)
      .paginate(page: 1, per_page: 200)
  end

  def show
    @item = Gw::WebmailAddressGroup.find(params[:id])
    return error_auth unless @item.readable?

    @groups = @item.children
    @items = @item.addresses.order(@orders)
  end
end
