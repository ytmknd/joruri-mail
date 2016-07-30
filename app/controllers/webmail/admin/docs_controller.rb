class Webmail::Admin::DocsController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  def pre_dispatch
  end
  
  def index
    @items = Webmail::Doc.state_public.order(:sort_no, :id)
      .paginate(page: params[:page], per_page: params[:limit])

    _index @items
  end

  def show
    @item = Webmail::Doc.find_by(id: params[:id])
    return http_error(404) unless @item
    return error_auth unless @item.readable?

    _show @item
  end
end