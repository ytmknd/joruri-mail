# encoding: utf-8
class Gw::Admin::Webmail::MailboxesController < Gw::Controller::Admin::Base
  require "net/imap"
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"
  
  def pre_dispatch
    @mailbox  = Gw::WebmailMailbox.load_mailbox(params[:mailbox])
    @item     = @mailbox.dup
    http_error(404) unless @item
  end
  
  def load_mailboxes
    load_starred_mails
    reload = flash[:gw_webmail_load_mailboxes]
    flash.delete(:gw_webmail_load_mailboxes)
    Gw::WebmailMailbox.load_quota(true)
    Gw::WebmailMailbox.load_mailboxes(reload)
  end
  
  def reset_mailboxes(mailboxes = [:all])
    flash[:gw_webmail_load_mailboxes] = mailboxes.uniq
  end
  
  def load_starred_mails
    mailbox_uids = flash[:gw_webmail_load_starred_mails]
    flash.delete(:gw_webmail_load_starred_mails)
    Gw::WebmailMailbox.load_starred_mails(mailbox_uids)
  end
  
  def reset_starred_mails(mailbox_uids = {'INBOX' => [:all]})
    flash[:gw_webmail_load_starred_mails] = mailbox_uids
  end
  
  def index
    @item      = @mailbox
    @mailboxes = load_mailboxes
  end
  
  def new
    @item = Gw::WebmailMailbox.new({
      :path => "" #"#{@mailbox.id}."
    })
    @mailboxes = load_mailboxes
  end
  
  def create
    @item.attributes = params[:item]
    
    raise @item.errors.add(:base, "権限がありません。") unless @item.creatable?
    raise unless @item.valid?
    begin
      Core.imap.create(@item.path + Net::IMAP.encode_utf7(@item.title))
      reset_mailboxes
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
    @mailboxes = load_mailboxes
    flash.now[:notice] = '登録処理に失敗しました。'
    respond_to do |format|
      format.html { render :action => :new }
      format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
    end
  end
  
  def update
    @item.attributes = params[:item]
    
    raise @item.errors.add(:base, "権限がありません。") unless @item.editable?
    raise unless @item.valid?
    begin
      Gw::WebmailMailNode.delete_nodes(@mailbox.name)
      new_name = @item.path + Net::IMAP.encode_utf7(@item.title)
      Core.imap.rename(@mailbox.name, new_name)
      reset_mailboxes
      
      uids = Gw::WebmailMailNode.find_ref_nodes(@mailbox.name).map{|x| x.uid}
      Core.imap.select('Star')
      num = Core.imap.uid_store(uids, "+FLAGS", [:Deleted]).size rescue 0
      Core.imap.expunge
      if num > 0
        Gw::WebmailMailNode.delete_ref_nodes(@mailbox.name)
        reset_starred_mails({new_name => [:all]})
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
    @mailboxes = load_mailboxes
    flash.now[:notice] = '更新処理に失敗しました。'
    return respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
    end
  end
  
  def destroy
    _destroy(@item, :location => gw_webmail_mailboxes_path('INBOX'))
  end
  
  def _destroy(item, options = {}, &block)
    raise @item.errors.add(:base, "権限がありません。") unless @item.deletable?
    
    delete_complete = @item.name =~ /^Trash\./
    short_name = @item.path.blank? ? @item.name : @item.name[@item.path.size, @item.name.size]
    new_name = "Trash.#{short_name}"
    if !delete_complete && Core.imap.list('', "Trash.#{short_name}")
      raise @item.errors.add(:base, "同じ名前のフォルダが既に存在します。")  
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
            reset_starred_mails({new_name => [:all]}) unless delete_complete
          end
        end
      end
      Gw::WebmailMailNode.delete_nodes(@item.name)
      if delete_complete
        Core.imap.delete(@item.name)
      else
        Core.imap.rename(@item.name, new_name)
      end
      reset_mailboxes
      
      uids = Gw::WebmailMailNode.find_ref_nodes(@mailbox.name).map{|x| x.uid}
      num = Gw::WebmailMail.delete_all('Star', uids)
      if num > 0
        Gw::WebmailMailNode.delete_ref_nodes(@mailbox.name)
        reset_starred_mails({new_name => [:all]}) unless delete_complete
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
    @mailboxes = load_mailboxes
    flash.now[:notice] = '削除処理に失敗しました。'
    return respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
    end
  end
  
end
