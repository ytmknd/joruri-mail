class Gw::Admin::Webmail::MailboxesController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  before_action :set_mailboxes
  before_action :set_item, only: [:create, :update, :destroy]
  after_action :reload_mailboxes, only: [:create, :update, :destroy]

  def pre_dispatch
    @mailbox  = Gw::WebmailMailbox.load_mailbox(params[:mailbox])
    return http_error(404) unless @mailbox
  end

  def index
    @item = @mailbox
  end

  def new
    @item = Gw::WebmailMailbox.new(path: '')
  end

  def create
    @item.attributes = item_params

    raise @item.errors.add(:base, "権限がありません。") unless @item.creatable?
    raise unless @item.valid?
    begin
      Core.imap.create(@item.path + Net::IMAP.encode_utf7(@item.title))
    rescue => e
      raise @item.errors.add(:base, "#{e}")
    end

    flash[:notice] = '登録処理が完了しました。'
    status = params[:_created_status] || :created
    respond_to do |format|
      format.html { redirect_to url_for(:action => :index) }
      format.xml  { render :xml => item.to_xml(:dasherize => false), :status => status, :location => url_for(:action => :index) }
    end
  rescue => e
    flash.now[:notice] = '登録処理に失敗しました。'
    respond_to do |format|
      format.html { render :action => :new }
      format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
    end
  end

  def update
    @item.attributes = item_params

    raise @item.errors.add(:base, "権限がありません。") unless @item.editable?
    raise unless @item.valid?
    begin
      Gw::WebmailMailNode.delete_nodes(@mailbox.name)
      new_name = @item.path + Net::IMAP.encode_utf7(@item.title)
      Core.imap.rename(@mailbox.name, new_name)

      uids = Gw::WebmailMailNode.find_ref_nodes(@mailbox.name).map{|x| x.uid}
      Core.imap.select('Star')
      num = Core.imap.uid_store(uids, "+FLAGS", [:Deleted]).size rescue 0
      Core.imap.expunge
      if num > 0
        Gw::WebmailMailNode.delete_ref_nodes(@mailbox.name)
        reload_starred_mails({new_name => [:all]})
      end
    rescue => e
      raise @item.errors.add(:base, "#{e}")
    end

    flash[:notice] = '更新処理が完了しました。'
    respond_to do |format|
      format.html { redirect_to gw_webmail_mailboxes_path(new_name) }
      format.xml  { head :ok }
    end
  rescue => e
    flash.now[:notice] = '更新処理に失敗しました。'
    return respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
    end
  end

  def destroy
    raise @item.errors.add(:base, "権限がありません。") unless @item.deletable?

    delete_complete = @item.trash_box?(:children)
    short_name = @item.path.blank? ? @item.name : @item.name[@item.path.size, @item.name.size]
    new_name = "Trash.#{short_name}"
    if !delete_complete && Core.imap.list('', "Trash.#{short_name}")
      raise @item.errors.add(:base, "同じ名前のフォルダーが既に存在します。")  
    end

    begin
      parent = @item.path.to_s.gsub(/\.+$/, '')
      parent = "INBOX" if parent.blank?
      if children = Core.imap.list('', "#{@item.name}.*")
        children.each do |box|
          Gw::WebmailMailNode.delete_nodes(box.name)
          if delete_complete
            Core.imap.delete(box.name)
          #else
          #  Core.imap.rename(box.name, "#{new_name}.#{box.name[@item.name.size + 1, box.name.size]}")
          end

          uids = Gw::WebmailMailNode.find_ref_nodes(box.name).map{|x| x.uid}
          num = Gw::WebmailMail.delete_all('Star', uids)
          if num > 0
            Gw::WebmailMailNode.delete_ref_nodes(box.name)
            reload_starred_mails({new_name => [:all]}) unless delete_complete
          end
        end
      end
      Gw::WebmailMailNode.delete_nodes(@item.name)
      if delete_complete
        Core.imap.delete(@item.name)
      else
        Core.imap.rename(@item.name, new_name)
      end

      uids = Gw::WebmailMailNode.find_ref_nodes(@mailbox.name).map{|x| x.uid}
      num = Gw::WebmailMail.delete_all('Star', uids)
      if num > 0
        Gw::WebmailMailNode.delete_ref_nodes(@mailbox.name)
        reload_starred_mails({new_name => [:all]}) unless delete_complete
      end
    rescue => e
      raise @item.errors.add(:base, "#{e}")
    end

    flash[:notice] = '削除処理が完了しました。'
    respond_to do |format|
      format.html { redirect_to url_for(:action => :index, :mailbox => parent) }
      format.xml  { head :ok }
    end
  rescue => e
    flash.now[:notice] = '削除処理に失敗しました。'
    return respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
    end
  end

  private

  def item_params
    params.require(:item).permit(:path, :title)
  end

  def set_item
    @item = @mailbox.dup
  end

  def set_mailboxes
    @mailboxes = Gw::WebmailMailbox.load_mailboxes
  end

  def reload_mailboxes
    @mailboxes = Gw::WebmailMailbox.load_mailboxes(:all)
  end

  def reload_starred_mails(mailbox_uids = {'INBOX' => [:all]})
    Gw::WebmailMailbox.load_starred_mails(mailbox_uids)
  end
end
