class Gw::Admin::Webmail::MailboxesController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout "admin/gw/webmail"

  after_action :reload_mailboxes, only: [:create, :update, :destroy]

  def pre_dispatch
    @mailboxes = Gw::WebmailMailbox.load_mailboxes
    @mailbox = @mailboxes.detect { |box| box.name == params[:mailbox] }
    return http_error(404) unless @mailbox

    @item = Gw::WebmailMailbox.load_mailboxes.detect { |box| box.name == params[:mailbox] }
  end

  def index
    @item = @mailbox
  end

  def new
    @item = Gw::WebmailMailbox.new(path: '')
  end

  def create
    return http_error(403) unless @item.creatable?

    @item = Gw::WebmailMailbox.new(user_id: Core.current_user.id)
    @item.attributes = item_params

    if @item.valid?
      begin
        @item.create_mailbox(@item.path_and_encoded_title)
      rescue => e
        @item.errors.add(:base, e.to_s)
      end
    end

    if @item.errors.present?
      flash.now[:notice] = '登録処理に失敗しました。'
      render :new
    else
      flash[:notice] = '登録処理が完了しました。'
      redirect_to action: :index
    end
  end

  def update
    return http_error(403) unless @item.editable?

    old_name = @item.name
    @item.attributes = item_params
    new_name = @item.path_and_encoded_title

    if @item.valid?
      begin
        @item.rename_mailbox(new_name)
  
        uids = Gw::WebmailMailNode.find_ref_nodes(old_name).map{|x| x.uid}
        Core.imap.select('Star')
        num = Core.imap.uid_store(uids, "+FLAGS", [:Deleted]).size rescue 0
        Core.imap.expunge
        if num > 0
          Gw::WebmailMailNode.delete_ref_nodes(old_name)
          reload_starred_mails({new_name => [:all]})
        end
      rescue => e
        @item.errors.add(:base, e.to_s)
      end
    end

    if @item.errors.present?
      flash.now[:notice] = '更新処理に失敗しました。'
      render :index
    else
      flash[:notice] = '更新処理が完了しました。'
      redirect_to action: :index, mailbox: new_name
    end
  end

  def destroy
    return http_error(403) unless @item.deletable?

    old_name = @item.name
    delete_complete = @item.trash_box?(:children)
    short_name = @item.path.blank? ? @item.name : @item.name[@item.path.size, @item.name.size]
    new_name = "Trash.#{short_name}"

    if !delete_complete && Core.imap.list('', "Trash.#{short_name}")
      @item.errors.add(:base, '同じ名前のフォルダーが既に存在します。')
    end

    parent = @item.path.to_s.gsub(/\.+$/, '')
    parent = "INBOX" if parent.blank?

    if @item.errors.blank? && @item.valid?
      begin
        if children = Core.imap.list('', "#{@item.name}.*")
          children.each do |box|
            if delete_complete
              Core.imap.delete(box.name)
            end
  
            uids = Gw::WebmailMailNode.find_ref_nodes(box.name).map{|x| x.uid}
            num = Gw::WebmailMail.delete_all('Star', uids)
            if num > 0
              Gw::WebmailMailNode.delete_ref_nodes(box.name)
              reload_starred_mails({new_name => [:all]}) unless delete_complete
            end
          end
        end
  
        if delete_complete
          @item.delete_mailbox
        else
          @item.rename_mailbox(new_name)
        end
  
        uids = Gw::WebmailMailNode.find_ref_nodes(old_name).map{|x| x.uid}
        num = Gw::WebmailMail.delete_all('Star', uids)
        if num > 0
          Gw::WebmailMailNode.delete_ref_nodes(old_name)
          reload_starred_mails({new_name => [:all]}) unless delete_complete
        end
      rescue => e
        @item.errors.add(:base, e.to_s)
      end
    end

    if @item.errors.present?
      flash.now[:notice] = '削除処理に失敗しました。'
      render :index
    else
      flash[:notice] = '削除処理が完了しました。'
      redirect_to action: :index, mailbox: parent
    end
  end

  private

  def item_params
    params.require(:item).permit(:path, :title)
  end

  def reload_mailboxes
    @mailboxes = Gw::WebmailMailbox.load_mailboxes(:all)
  end

  def reload_starred_mails(mailbox_uids = {'INBOX' => [:all]})
    Gw::WebmailMailbox.load_starred_mails(mailbox_uids)
  end
end
