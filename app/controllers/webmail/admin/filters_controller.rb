class Webmail::Admin::FiltersController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  def pre_dispatch
  end

  def index
    @items = Webmail::Filter.where(user_id: Core.user.id).order(:sort_no, :id)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Webmail::Filter.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Webmail::Filter.new(
      state: 'enabled',
      conditions_chain: 'and',
      sort_no: 0
    )
  end

  def create
    @item = Webmail::Filter.new(item_params)
    @item.user_id = Core.user.id
    _create(@item)
  end

  def update
    @item = Webmail::Filter.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id = Core.user.id

    _update(@item)
  end

  def destroy
    @item = Webmail::Filter.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item)
  end

  def apply
    @item = Webmail::Filter.find(params[:id])
    return error_auth unless @item.readable?
    return false unless request.post?

    @item.attributes = apply_item_params
    return false if @item.invalid?(:apply)

    @item.apply

    Webmail::Mailbox.load_mailboxes(:all)

    flash[:notice] = "#{@item.applied}件のメールに適用しました。"
    flash[:error] = "フィルター処理件数が規定値を超えたため、残り#{@item.delayed}件のメールはバックグラウンドで実行します。完了までに時間がかかる場合があります。" if @item.delayed > 0
    redirect_to action: :apply
  end

  private

  def item_params
    params.require(:item).permit(:name, :state, :sort_no, :conditions_chain, :action, :mailbox,
      :conditions_attributes => [:id, :column, :inclusion, :value, :_destroy])
  end

  def apply_item_params
    params.require(:item).permit(:target_mailbox, :include_sub)
  end
end
