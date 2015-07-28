# encoding: utf-8
class Gw::Admin::Webmail::ToolsController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"
  
  def index
    redirect_to :action => :batch_delete
  end
  
  def batch_delete
    @mailboxes = Gw::WebmailMailbox.load_mailboxes
    
    if request.get?
      @item = Gw::WebmailToolBatchDeleteSetting.new
      return render :action => :batch_delete
    end
    
    @item = Gw::WebmailToolBatchDeleteSetting.new(params[:item])
    unless @item.valid?
      return render :action => :batch_delete
    end
    
    delete_num = @item.batch_delete_mails(@mailboxes)
    
    @item.start_date = ''
    @item.end_date = ''
    flash.now[:notice] = "#{delete_num}件のメールを削除しました。"
  end
end