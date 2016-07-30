class Webmail::Admin::AddressSelector::AddressesController < Webmail::Controller::Admin::Base
  def pre_dispatch
    @orders = Webmail::Setting.load_address_orders
  end

  def index
    @items = Webmail::Address.where(user_id: Core.user.id)
      .search(params)
      .order(@orders)
      .paginate(page: 1, per_page: 200)
  end

  def show
    @item = Webmail::AddressGroup.find(params[:id])
    return error_auth unless @item.readable?

    @groups = @item.children
    @items = @item.addresses.order(@orders)
  end
end
