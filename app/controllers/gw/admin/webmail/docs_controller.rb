class Gw::Admin::Webmail::DocsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  def pre_dispatch
  end
  
  def index
    @items = Gw::WebmailDoc.state_public.order(:sort_no, :id)
      .paginate(page: params[:page], per_page: params[:limit])

    _index @items
  end

  def show
    @item = Gw::WebmailDoc.find_by(id: params[:id])
    return http_error(404) unless @item
    return error_auth unless @item.readable?

    _show @item
  end
end