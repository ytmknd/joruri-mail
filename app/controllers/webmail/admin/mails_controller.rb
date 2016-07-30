class Webmail::Admin::MailsController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Webmail::Controller::Admin::Mobile::Mail
  layout :select_layout
  rescue_from StandardError, with: :rescue_mail

  before_action :handle_mailto_scheme, if: -> { params[:src] == 'mailto' }
  before_action :check_user_email, only: [:new, :create, :edit, :update, :answer, :forward]
  before_action :check_posted_uids, only: [:move, :delete, :seen, :unseen, :register_spam]

  before_action :set_conf, only: [:index, :show, :move]
  before_action :set_address_histories, only: [:index, :show, :move]
  before_action :set_mail_form_size

  before_action :set_mailboxes, only: [:index, :show, :move, :empty]
  after_action :reload_mailboxes, only: [:destroy, :delete, :empty, :move, :seen, :unseen, :star, :register_spam]

  before_action :set_quota, only: [:index]
  after_action :reload_quota, only: [:destroy, :delete, :empty, :move, :seen, :unseen, :star, :register_spam]

  before_action :set_conditions_from_params, only: [:index, :show]
  before_action :set_sort_from_params, only: [:index, :show, :move]

  def pre_dispatch
    return redirect_to action: :index, mailbox: params[:mailbox] if params[:reset]

    @mailbox = Webmail::Mailbox.load_mailbox(params[:mailbox] || 'INBOX')
    return http_error(404) unless @mailbox
  end

  def index
    last_uid, recent, delayed = Webmail::Filter.apply_recents
    if recent && params[:reload].blank?
      reload_mailboxes
      reload_quota
    end
    if @mailbox.name == 'INBOX'
      @conditions += ['UID', "1:#{last_uid}"]
    end
    if delayed > 0
      flash.now[:error] = "新着メールのフィルター処理件数が規定値を超えたため、残り#{delayed}件はバックグラウンドで実行します。完了までに時間がかかる場合があります。"
    end

    @items = Webmail::Mail.paginate(select: @mailbox.name, conditions: @conditions,
      sort: @sort, page: params[:page], limit: @conf.mails_per_page, starred: params[:sort_starred])
  end

  def show
    @item = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'])
    return error_auth unless @item

    if params[:show_html_image]
      return http_error(404) unless @item.html_mail?
      return respond_to do |format|
        format.json { render :show_html }
      end
    end

    Core.title += " - #{@item.subject} - #{Core.current_user.email}"

    if from = Email.parse(@item.friendly_from_addr)
      @from_addr = CGI.escapeHTML(from.address)
      @from_name = ::NKF::nkf('-wx --cp932', from.name).gsub(/\0/, "") if from.name rescue nil
      @from_name = @from_name || @from_addr
    end

    if @item.unseen?
      mailbox_uids = get_mailbox_uids(@mailbox, @item.uid)
      mailbox_uids.each do |mailbox, uids|
        Webmail::Mail.seen_all(mailbox, uids)
      end
      reload_mailboxes

      @seen_flagged = true

      if @item.mdn_request_mode == :auto && !@item.notified? && !@mailbox.draft_box? && !@mailbox.sent_box?
        begin
          send_mdn_message(@item.mdn_request_mode)
        rescue => e
          flash.now[:notice] = "開封確認メールの自動送信に失敗しました。"
        end
      end
    end

    @pagination = Webmail::Mail.paginate_uid(params[:id],
      select: @mailbox.name, conditions: @conditions, sort: @sort, starred: params[:sort_starred])

    _show @item
  end

  def download
    @item = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'])
    return error_auth unless @item

    case
    when params[:download] == 'eml'
      filename = @item.subject + '.eml'
      msg = @item.rfc822
      send_data(msg, filename: filename, type: 'message/rfc822', disposition: 'attachment')
    when params[:download] == 'all'
      filename = sprintf("%07d_%s.zip", @item.uid, Util::File.filesystemize(@item.subject, length: 100))
      zipdata = @item.zip_attachments(encoding: request.user_agent =~ /Windows/ ? 'shift_jis' : 'utf-8')
      send_data(zipdata, type: 'application/zip', filename: filename, disposition: 'attachment')
    when params[:download]
      return download_attachment(params[:download])
    when params[:header]
      msg = @item.rfc822
      msg = msg.slice(0, msg.index("\r\n\r\n"))
      send_data(msg.gsub(/\r\n/m, "\n"), type: 'text/plain; charset=utf-8', disposition: 'inline')
    when params[:source]
      msg = @item.rfc822
      send_data(msg.gsub(/\r\n/m, "\n"), type: 'text/plain; charset=utf-8', disposition: 'inline')
    end
  end

  def download_attachment(no)
    return http_error(404) unless at = @item.attachments[no.to_i]

    if params[:thumbnail].present? && (data = at.thumbnail(attachment_thumbnail_options))
      type = 'image/jpeg'
    else
      data = at.body
      type = at.content_type
    end

    send_data(data, type: type, filename: at.name, disposition: params[:disposition].presence || at.disposition)
  end

  def new
    @item = Webmail::Mail.new
    @item.init_for_new(template: default_template, sign: default_sign)
    @item.init_from_flash(flash)
    @item.init_from_params(params)
    @item.append_mobile_notice_to_body if request.mobile? || request.smart_phone?
  end

  def create
    @item = Webmail::Mail.new(item_params)
    send_message(@item)
  end

  def edit
    @ref = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'])
    return http_error(404) unless @ref

    @item = Webmail::Mail.new(item_params)
    @item.init_for_edit(@ref, format: params[:mail_view])
    @item.init_from_flash(flash)
    @item.append_mobile_notice_to_body if request.mobile? || request.smart_phone?
    render :new
  end

  def update
    @ref = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'])
    return http_error(404) unless @ref

    @item = Webmail::Mail.new(item_params)
    send_message(@item, @ref) do
      if !params[:remain_draft] && @ref.draft?
        mailbox_uids = get_mailbox_uids(@mailbox, @ref.uid)
        mailbox_uids.each do |mailbox, uids|
          num = Webmail::Mail.delete_all(mailbox, uids, true)
          if num > 0
            Webmail::MailNode.delete_nodes(mailbox, uids)
          end
        end
      end
    end
  end

  def answer
    @ref = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'])
    return http_error(404) unless @ref

    @item = Webmail::Mail.new(item_params)
    @item.reference = @ref

    if request.post?
      return send_message(@item, @ref) do
        mailbox_uids = get_mailbox_uids(@mailbox, @ref.uid)
        mailbox_uids.each do |mailbox, uids|
          Core.imap.select(mailbox)
          Core.imap.uid_store(uids, "+FLAGS", [:Answered])
        end
      end
    end

    @item.init_for_answer(@ref, format: params[:mail_view],
      sign: default_sign,
      sign_pos: Webmail::Setting.user_config_value(:sign_position),
      all: params[:all],
      quote: params[:qt]
    )
    @item.init_from_flash(flash)
    @item.append_mobile_notice_to_body if request.mobile? || request.smart_phone?
    render :new
  end

  def forward
    @ref = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'])
    return http_error(404) unless @ref

    @item = Webmail::Mail.new(item_params)

    if request.post?
      return send_message(@item, @ref) do
        mailbox_uids = get_mailbox_uids(@mailbox, @ref.uid)
        mailbox_uids.each do |mailbox, uids|
          Core.imap.select(mailbox)
          Core.imap.uid_store(uids, "+FLAGS", "$Forwarded")
        end
      end
    end

    @item.init_for_forward(@ref, format: params[:mail_view],
      sign: default_sign,
      sign_pos: Webmail::Setting.user_config_value(:sign_position)
    )
    @item.init_from_flash(flash)
    @item.append_mobile_notice_to_body if request.mobile? || request.smart_phone?
    render :new
  end

  def send_message(item, ref = nil, &block)
    config = Webmail::Setting.user_config_value(:mail_from)
    ma = Mail::Address.new
    ma.address      = Core.current_user.email
    ma.display_name = Core.current_user.name if config != "only_address"
    item.in_from = ma.to_s

    ## submit/file
    if params[:commit_file].present?
      item.save_tmp_attachments
      return render :new
    end

    ## submit/destroy
    if params[:commit_destroy].present?
      item.delete_tmp_attachments
      return redirect_to action: :close
    end

    ## submit/draft
    if params[:commit_draft].present?
      unless item.valid?(:draft)
        return render :new
      end
      return save_as_draft(item, ref, &block)
    end

    ## submit/send
    unless item.valid?(:send)
      return render :new
    end

    begin
      mail = item.prepare_mail(request)
      mail.delivery_method(:smtp, ActionMailer::Base.smtp_settings)
      mail.deliver
    rescue => e
      flash.now[:error] = "メールの送信に失敗しました。（#{e}）"
      respond_to do |format|
        format.html { render :action => :new }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
      return
    end

    item.delete_tmp_attachments
    Webmail::MailAddressHistory.save_user_histories(item.in_to_addrs)

    yield if block_given?

    ## save to 'Sent'
    begin
      mail.header[:bcc].include_in_headers = true
      Timeout.timeout(60) { Core.imap.append('Sent', mail.to_s, [:Seen], Time.now) }
    rescue => e
      flash[:error] = "メールは送信できましたが、送信トレイへの保存に失敗しました。（#{e}）"
    end

    status         = params[:_created_status] || :created
    location       = url_for(action: :close)
    respond_to do |format|
      format.html { redirect_to(location) }
      format.xml  { render :xml => item.to_xml(:dasherize => false), :status => status, :location => location }
    end
  end

  def save_as_draft(item, ref, &block)
    begin
      mail = item.prepare_mail(request)
      mail.header[:bcc].include_in_headers = true
      flags = [:Seen, :Draft].tap { |a| a << :Flagged if ref && ref.starred? }
      Timeout.timeout(60) { Core.imap.append('Drafts', mail.to_s, flags, Time.now) }
    rescue => e
      flash.now[:error] = "下書き保存に失敗しました。（#{e}）"
      respond_to do |format|
        format.html { render :action => :new }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
      return
    end

    item.delete_tmp_attachments

    yield if block_given?

    status         = params[:_created_status] || :created
    location       = url_for(action: :close)
    respond_to do |format|
      format.html { redirect_to(location) }
      format.xml  { render :xml => item.to_xml(:dasherize => false), :status => status, :location => location }
    end
  end

  def destroy
    @item = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'], fetch: ['FLAGS'])
    return error_auth unless @item

    changed_num = 0
    changed_mailbox_uids = {}

    mailbox_uids = get_mailbox_uids(@mailbox, @item.uid)
    mailbox_uids.each do |mailbox, uids|
      num = Webmail::Mail.delete_all(mailbox, uids)
      if num > 0
        Webmail::MailNode.delete_nodes(mailbox, uids)
        changed_mailbox_uids['Trash'] = [:all]
      end
      changed_num += num if mailbox !~ /^(Star)$/
    end

    if changed_num > 0
      reload_starred_mails(changed_mailbox_uids) if @item.starred?

      flash[:notice] = 'メールを削除しました。' unless new_window?
      respond_to do |format|
        format.html do
          redirect_to action: new_window? ? :close : :index
        end
        format.xml  { head :ok }
      end
    else
      flash[:error] = 'メールの削除に失敗しました。'
      respond_to do |format|
        format.html do
          redirect_to action: new_window? ? :close : :index
        end
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def move
    uids = params[:item][:ids].keys.map(&:to_i).select(&:positive?)
    return http_error if uids.blank?

    if !params[:item][:mailbox]
      @items = Webmail::Mail.find(select: @mailbox.name, conditions: ['UID', uids] + ['UNDELETED'], sort: @sort)
      return render template: 'webmail/admin/mails/move'
    end

    changed_num = 0
    changed_mailbox_uids = {}
    include_starred_uid = Webmail::Mail.include_starred_uid?(@mailbox.name, uids)

    mailbox_uids = get_mailbox_uids(@mailbox, uids)
    mailbox_uids.each do |mailbox, uids|
      if mailbox =~ /^(Star)$/
        num = 0
        if params[:copy].blank? #move
          num = Webmail::Mail.delete_all(mailbox, uids, true)
          Webmail::MailNode.delete_nodes(mailbox, uids) if num > 0
        end
      else
        if params[:copy].blank? #move
          num = Webmail::Mail.move_all(mailbox, params[:item][:mailbox], uids)
          Webmail::MailNode.delete_nodes(mailbox, uids) if num > 0
        else
          num = Webmail::Mail.copy_all(mailbox, params[:item][:mailbox], uids)
        end
        changed_num += num
      end
      if num > 0
        changed_mailbox_uids[params[:item][:mailbox]] = [:all]
      end
    end

    reload_starred_mails(changed_mailbox_uids) if include_starred_uid

#    num = 0
#    Webmail::Mail.find(select: @mailbox.name, conditions: cond).each do |item|
#      num += 1 if item.move(params[:item][:mailbox])
#    end

    label = params[:copy].blank? ? '移動' : 'コピー'
    flash[:notice] = "#{changed_num}件のメールを#{label}しました。" unless new_window?
    redirect_to action: new_window? ? :close : :index
  end

  def delete
    uids = params[:item][:ids].keys.map(&:to_i).select(&:positive?)
    return http_error if uids.blank?

    changed_num = 0
    changed_mailbox_uids = {}
    include_starred_uid = Webmail::Mail.include_starred_uid?(@mailbox.name, uids)

    mailbox_uids = get_mailbox_uids(@mailbox, uids)
    mailbox_uids.each do |mailbox, uids|
      num = Webmail::Mail.delete_all(mailbox, uids)
      if num > 0
        Webmail::MailNode.delete_nodes(mailbox, uids)
        changed_mailbox_uids['Trash'] = [:all]
      end
      changed_num += num if mailbox !~ /^(Star)$/
    end

    reload_starred_mails(changed_mailbox_uids) if include_starred_uid

#    Webmail::Mail.find(select: @mailbox.name, conditions: cond).each do |item|
#      num += 1 if item.destroy
#    end

    flash[:notice] = "#{changed_num}件のメールを削除しました。"
    redirect_to action: :index
  end

  def seen
    uids = params[:item][:ids].keys.map(&:to_i).select(&:positive?)
    return http_error if uids.blank?

    changed_num = 0
    mailbox_uids = get_mailbox_uids(@mailbox, uids)
    mailbox_uids.each do |mailbox, uids|
      num = Webmail::Mail.seen_all(mailbox, uids)
      changed_num += num if mailbox !~ /^(Star)$/
    end

    flash[:notice] = "#{changed_num}件のメールを既読にしました。"
    redirect_to action: :index
  end

  def unseen
    uids = params[:item][:ids].keys.map(&:to_i).select(&:positive?)
    return http_error if uids.blank?

    changed_num = 0
    mailbox_uids = get_mailbox_uids(@mailbox, uids)
    mailbox_uids.each do |mailbox, uids|
      num = Webmail::Mail.unseen_all(mailbox, uids)
      changed_num += num if mailbox !~ /^(Star)$/
    end

    flash[:notice] = "#{changed_num}件のメールを未読にしました。"
    redirect_to action: :index
  end

  def register_spam
    uids = params[:item][:ids].keys.map(&:to_i).select(&:positive?)
    return http_error if uids.blank?

    items = Webmail::Mail.find(select: @mailbox.name, conditions: ['UID', uids] + ['UNDELETED'])
    return redirect_to action: :index if items.blank?

    Webmail::Filter.register_spams(items)

    changed_num = 0
    changed_mailbox_uids = {}
    include_starred_uid = Webmail::Mail.include_starred_uid?(@mailbox.name, uids)

    mailbox_uids = get_mailbox_uids(@mailbox, uids)
    mailbox_uids.each do |mailbox, uids|
      num = Webmail::Mail.delete_all(mailbox, uids)
      if num > 0
        Webmail::MailNode.delete_nodes(mailbox, uids)
        changed_mailbox_uids['Trash'] = [:all]
      end
      changed_num += num if mailbox !~ /^(Star)$/
    end

    reload_starred_mails(changed_mailbox_uids) if include_starred_uid

    flash[:notice] = "#{items.count}件のメールを迷惑メールに登録しました。"
    redirect_to action: :index
  end

  def empty
    changed_mailbox_uids = {}

    @mailboxes.reverse.each do |box|
      if box.trash_box?(:children)
        begin
          Webmail::MailNode.delete_nodes(box.name)
          Core.imap.delete(box.name)

          uids = Webmail::MailNode.find_ref_nodes(box.name).map{|x| x.uid}
          num = Webmail::Mail.delete_all('Star', uids)
          if num > 0
            Webmail::MailNode.delete_ref_nodes(box.name)
            changed_mailbox_uids[box.name] = [:all]
          end
        rescue => e
        end
      end
    end

    Core.imap.select(@mailbox.name)
    uids = Core.imap.uid_search(['UNDELETED'], 'utf-8')

    mailbox_uids = get_mailbox_uids(@mailbox, uids)
    mailbox_uids.each do |mailbox, uids|
      num = Webmail::Mail.delete_all(mailbox, uids, true)
      if num > 0
        Webmail::MailNode.delete_nodes(mailbox, uids)
        changed_mailbox_uids[mailbox] = [:all]
      end
    end

    reload_starred_mails(changed_mailbox_uids)

    flash[:notice] = "ごみ箱を空にしました。"
    respond_to do |format|
      format.html { redirect_to action: :index }
      format.xml  { head :ok }
    end
  end
  
  def send_mdn
    @item = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'])
    return error_auth unless @item && @item.has_disposition_notification_to?

    if request.xhr?
      send_mdn_message(:manual)
      return render text: ''
    else
      begin
        send_mdn_message(:manual)
        flash[:notice] = "開封確認メールを送信しました。"
      rescue => e
        flash[:notice] = "開封確認メールの送信に失敗しました。"
      end
      return redirect_to action: :show
    end
  end

  def reset_address_history
    Webmail::MailAddressHistory.where(user_id: Core.current_user.id).delete_all

    flash[:notice] = 'クイックアドレス帳をリセットしました。'
    redirect_to action: :index
  end

  def star
    @item = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'], fetch: ['FLAGS'])
    return error_auth unless @item

    starred = @item.starred?
    changed_mailbox_uids = {}

    mailbox_uids = get_mailbox_uids(@mailbox, @item.uid)
    mailbox_uids.each do |mailbox, uids|
      if starred
        num = Webmail::Mail.unstar_all(mailbox, uids)
      else
        num = Webmail::Mail.star_all(mailbox, uids)
      end
      if num > 0
        changed_mailbox_uids[mailbox] = uids
      end
    end

    reload_starred_mails(changed_mailbox_uids)

    if request.mobile?
      if params[:from] == 'list' || @mailbox.star_box?
        redirect_to action: :index, id: params[:id], mobile: :list
      else
        redirect_to action: :show, id: params[:id]
      end
    else
      render text: "OK"
    end
  end

  def label
    @item = Webmail::Mail.find_by_uid(params[:id], select: @mailbox.name, conditions: ['UNDELETED'], fetch: ['FLAGS'])
    return error_auth unless @item

    @label_confs = Webmail::Setting.load_label_confs

    label_id = params[:label].to_i
    labeled = @item.labeled?(label_id)

    mailbox_uids = get_mailbox_uids(@mailbox, @item.uid)
    mailbox_uids.each do |mailbox, uids|
      if label_id == 0
        Webmail::Mail.unlabel_all(mailbox, uids)
      elsif labeled
        Webmail::Mail.unlabel_all(mailbox, uids, label_id)
      else
        Webmail::Mail.label_all(mailbox, uids, label_id)
      end
    end

    if label_id == 0
      @item.flags.clear
    elsif labeled
      @item.flags.delete("$label#{label_id}")
    else
      @item.flags << "$label#{label_id}"
    end

    render layout: false
  end

  def new_window?
    params[:new_window] == '1'
  end

  private

  def select_layout
    case action_name.to_sym
    when :new, :create, :edit, :update, :answer, :forward, :close
      'admin/webmail/mail_form'
    when :show, :move
      new_window? ? 'admin/webmail/mail_form' : 'admin/webmail/base'
    else
      'admin/webmail/base'
    end
  end

  def keep_params(options = {})
    if options[:mailbox].blank? &&
       (options[:controller].blank? || options[:controller].in?([controller_name, controller_path]))
      keeps = params.slice(:page, :search, :s_keyword, :s_column, :s_status, :s_label,
        :sort_key, :sort_order, :sort_starred, :new_window)
      options = options.reverse_merge(keeps)
    end
    options
  end

  def handle_mailto_scheme
    mailto = Util::Mailto.parse(params[:uri])
    [:to, :cc, :bcc, :subject, :body].each { |k| mailto[k] = params[k] if params[k] }
    redirect_to new_webmail_mail_path(mailto.merge(mailbox: 'INBOX'))
  end

  def check_user_email
    if Core.current_user.email.blank?
      return render text: "メールアドレスが登録されていません。", layout: true
    end
  end

  def check_posted_uids
    if !params[:item] || !params[:item][:ids]
      return redirect_to action: :index
    end    
  end

  def item_params
    return {} unless params[:item]
    params.require(:item).permit(:in_to, :in_cc, :in_bcc, :in_subject, :in_body, :in_html_body,
      :in_format, :in_request_mdn, :in_files, :tmp_id, :tmp_attachment_ids => [])
  end

  def set_conf
    @conf = Webmail::Setting.user_config_values([
      :mails_per_page, :mail_list_subject, :mail_list_from_address, :mail_address_history,
      :html_mail_view, :mail_attachment_view, :mail_open_window,
      :mail_form_size,
    ])
    @conf.mails_per_page = request.mobile? ? 20 : (@conf.mails_per_page.presence || 20).to_i
    @conf.mail_address_history = (@conf.mail_address_history.presence || 10).to_i
    @conf.html_mail_view = @conf.html_mail_view.presence || 'html'
    @mail_form_size = @conf.mail_form_size.presence || 'medium'

    @conf.mail_labels = Webmail::Setting.load_label_confs
  end

  def set_address_histories
    if @conf.mail_address_history != 0 && !new_window?
      @address_histories = Webmail::MailAddressHistory.load_user_histories(@conf.mail_address_history)
    end
  end

  def set_mail_form_size
    @mail_form_size ||= Webmail::Setting.user_config_value(:mail_form_size, 'medium')
  end

  def set_mailboxes
    if !new_window?
      @mailboxes = Webmail::Mailbox.load_mailboxes(params[:reload].present? ? :all : nil)
    end
  end

  def reload_mailboxes
    @mailboxes = Webmail::Mailbox.load_mailboxes(:all)
  end

  def set_quota
    @quota = Webmail::Mailbox.load_quota(params[:reload].present?)
  end

  def reload_quota
    @quota = Webmail::Mailbox.load_quota(true)
  end

  def set_conditions_from_params
    fromto = @mailbox.sent_box? || @mailbox.draft_box? ? 'TO' : 'FROM'
    @conditions = Webmail::Mail.make_conditions_from_params(params, fromto)
  end

  def set_sort_from_params
    @sort = Webmail::Mail.make_sort_from_params(params)
  end

  def reload_starred_mails(mailbox_uids = {'INBOX' => :all})
    Util::Database.lock_by_name(Core.current_user.account) do
      Webmail::Mailbox.load_starred_mails(mailbox_uids)
    end
  end

  def default_sign
    if !request.mobile? && !request.smart_phone?
      Webmail::Sign.default_sign
    end
  end

  def default_template
    if !request.mobile? && !request.smart_phone?
      Webmail::Template.default_template
    end
  end

  def send_mdn_message(mdn_mode)
    mdn = Webmail::Mail.new
    mdn.in_from ||= Core.current_user.email_format
    mail = mdn.prepare_mdn(@item, mdn_mode.to_s, request)
    mail.delivery_method(:smtp, ActionMailer::Base.smtp_settings)
    mail.deliver

    Core.imap.uid_store(@item.uid, "+FLAGS", "$Notified")
    @item.flags << "$Notified"
  end

  def get_mailbox_uids(mailbox, uids)
    mailbox_uids = {}
    uids = [uids] if uids.is_a?(Fixnum)
    if mailbox.star_box?
      nodes = Webmail::MailNode.find_nodes(mailbox.name, uids)
      nodes = nodes.select{|x| x.ref_mailbox && x.ref_uid}.group_by(&:ref_mailbox)
      nodes.each do |k,v| 
        mailbox_uids[k] = v.map{|x| x.ref_uid}
      end
    else
      nodes = Webmail::MailNode.find_ref_nodes(mailbox.name, uids)
      nodes = nodes.group_by(&:mailbox)
      nodes.each do |k,v| 
        mailbox_uids[k] = v.map{|x| x.uid}
      end
    end
    mailbox_uids[mailbox.name] = uids
    mailbox_uids
  end

  def rescue_mail_action?
    (request.post? || request.put? || request.patch?) &&
      (action_name.in?(%w(create update answer forward mobile_send)))
  end

  def rescue_mail(e)
    raise e unless rescue_mail_action?

    @mailbox = Webmail::Mailbox.where(user_id: Core.current_user.id, name: params[:mailbox] || 'INBOX').first
    raise e unless @mailbox

    @item = Webmail::Mail.new(item_params)
    flash.now[:error] = "サーバーエラーが発生しました。時間をおいて再度送信してください。（#{e}）"
    render :new
  end
end
