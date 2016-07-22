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

    @f_item = Gw::WebmailFilter.new
    return false unless request.post?

    @f_item.attributes = f_item_params

    ## validation
    @f_item.errors.add :base, "適用するフォルダを入力してください。" if @f_item.mailbox.blank?
    @f_item.errors.add :base, "適用する条件が見つかりません。" if @item.conditions.size == 0
    return false if @f_item.errors.size > 0

    begin
      timeout = Sys::Lib::Timeout.new(60)
      mailboxes = [@f_item.mailbox]
      mailboxes += Core.imap.list('', "#{@f_item.mailbox}.*").to_a.map(&:name) if @f_item.include_sub == '1'
      mailboxes.each do |mailbox|
        @item.apply(select: mailbox, conditions: ['NOT', 'DELETED'], timeout: timeout)
      end
    rescue Sys::Lib::Timeout::Error => e
      flash[:error] = "フィルタ処理がタイムアウトしました。（#{e.second}秒）"
    end

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
    redirect_to action: :apply
  end

  private

  def item_params
    params.require(:item).permit(:name, :state, :sort_no, :conditions_chain, :action, :mailbox,
      :conditions_attributes => [:id, :column, :inclusion, :value, :_destroy])
  end

  def f_item_params
    params.require(:f_item).permit(:mailbox, :include_sub)
  end
end
