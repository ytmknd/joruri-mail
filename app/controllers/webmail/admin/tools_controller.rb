class Webmail::Admin::ToolsController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  def index
    redirect_to action: :batch_delete
  end

  def batch_delete
    @mailboxes = Webmail::Mailbox.load_mailboxes

    if request.get?
      @item = Webmail::Tool::BatchDelete.new
      return render :batch_delete
    end

    @item = Webmail::Tool::BatchDelete.new(item_params)
    unless @item.valid?
      return render :batch_delete
    end

    delete_num = @item.batch_delete_mails(@mailboxes)

    @item.start_date = ''
    @item.end_date = ''
    flash.now[:notice] = "#{delete_num}件のメールを削除しました。"
  end

  private

  def item_params
    params.require(:item).permit(:mailbox_id, :start_date, :end_date, :include_starred)
  end
end
