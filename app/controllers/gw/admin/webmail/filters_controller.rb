class Gw::Admin::Webmail::FiltersController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  def pre_dispatch
    imap = Core.imap
    #return error_auth unless Core.user.has_auth?(:designer)
  #rescue => e
    #render :text => %Q(<div class="railsException">#{e}</div>), :layout => true
  end

  def index
    @items = Gw::WebmailFilter.readable.where(user_id: Core.user.id).order(:sort_no, :id)
      .paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Gw::WebmailFilter.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Gw::WebmailFilter.new(
      state: 'enabled',
      conditions_chain: 'and',
      sort_no: 0
    )
  end

  def create
    @item = Gw::WebmailFilter.new(item_params)
    @item.user_id = Core.user.id
    _create(@item)
  end

  def update
    @item = Gw::WebmailFilter.find(params[:id])
    return error_auth unless @item.editable?
    @item.attributes = item_params
    @item.user_id = Core.user.id

    _update(@item)
  end

  def destroy
    @item = Gw::WebmailFilter.find(params[:id])
    return error_auth unless @item.deletable?
    _destroy(@item)
  end

  def apply
    @item = Gw::WebmailFilter.find(params[:id])
    return error_auth unless @item.readable?
    return false unless request.post?

    @item.attributes = apply_item_params
    return false if @item.invalid?(:apply)

    @item.apply

    if @item.applied > 0
      changed_mailbox_uids = {}
      case @item.action
      when 'move'
        changed_mailbox_uids[@item.mailbox] = [:all]
      when 'delete'
        changed_mailbox_uids['Trash'] = [:all]
      end
      Gw::WebmailMailbox.load_starred_mails(changed_mailbox_uids)
      Gw::WebmailMailbox.load_mailboxes(:all)
    end

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
