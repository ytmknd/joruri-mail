class Webmail::Admin::MailboxesController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout 'admin/webmail/base'

  after_action :reload_mailboxes, only: [:create, :update, :destroy]

  def pre_dispatch
    @mailboxes = Webmail::Mailbox.load_mailboxes
    @mailbox = @mailboxes.detect { |box| box.name == params[:mailbox] }
    return http_error(404) unless @mailbox

    @item = Webmail::Mailbox.load_mailboxes.detect { |box| box.name == params[:mailbox] }
  end

  def index
    @item = @mailbox
  end

  def new
    @item = Webmail::Mailbox.new(path: '')
  end

  def create
    return http_error(403) unless @item.creatable?

    @item = Webmail::Mailbox.new(user_id: Core.current_user.id)
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

    begin
      if @item.trash_box?(:children)
        @item.descendants.each(&:delete_mailbox)
      else
        trash = @mailboxes.detect(&:use_as_trash?)
        @item.rename_mailbox("#{trash.name}#{trash.delim}#{@item.names.last}") if trash
      end
    rescue => e
      @item.errors.add(:base, e.to_s.force_encoding('utf-8'))
    end

    if @item.errors.present?
      flash.now[:notice] = '削除処理に失敗しました。'
      render :index
    else
      flash[:notice] = '削除処理が完了しました。'
      redirect_to action: :index, mailbox: @item.parent ? @item.parent.name : 'INBOX'
    end
  end

  private

  def item_params
    params.require(:item).permit(:path, :title)
  end

  def reload_mailboxes
    @mailboxes = Webmail::Mailbox.load_mailboxes(:all)
  end
end
