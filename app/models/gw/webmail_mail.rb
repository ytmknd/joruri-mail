class Gw::WebmailMail
  include Sys::Lib::Net::Imap
  include Sys::Lib::Mail

  FORMAT_TEXT = 'text'
  FORMAT_HTML = 'html'

  attr_accessor :charset, :in_to, :in_cc, :in_bcc, :in_from, :in_sender,
    :in_subject, :in_body, :in_html_body, :in_format, :in_files, :in_request_mdn,
    :tmp_id, :tmp_attachment_ids
  attr_reader :in_to_addrs, :in_cc_addrs, :in_bcc_addrs

  def initialize(attributes = nil)
    if attributes.is_a?(Gw::WebmailMailNode)
      @node = attributes
      self.uid     = @node.uid
      self.mailbox = @node.mailbox
      self.extend Gw::Model::Ext::WebmailNode
    elsif attributes.is_a?(String)
      parse(attributes)
    elsif attributes
      self.attributes = attributes
    end
  end

  def attributes=(attributes)
    attributes.each do |key, val|
      self.send("#{key}=", val)
    end
  end

  def charset
    @charset ||= Gw::WebmailSetting.user_config_value(:mail_encoding, 'ISO-2022-JP')
  end

  def node
    @node ||= find_node 
  end

  def find_node
    Gw::WebmailMailNode.where(user_id: Core.current_user.id, mailbox: mailbox, uid: uid).first
  end

  def reference=(reference)
    @reference = reference
  end

  def tmp_attachments
    return [] unless tmp_id
    Gw::WebmailMailAttachment.where(id: tmp_attachment_ids, tmp_id: tmp_id)
  end

  def delete_tmp_attachments
    return true unless tmp_id
    Gw::WebmailMailAttachment.where(tmp_id: tmp_id).destroy_all
  end

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  def valid?(mode = :send)
    @in_from_addr     = Email.parse_list(in_from)
    @in_to_addrs      = Email.parse_list(in_to)
    @in_cc_addrs      = Email.parse_list(in_cc)
    @in_bcc_addrs     = Email.parse_list(in_bcc)
    self.in_subject   = NKF.nkf('-Ww --no-best-fit-chars', in_subject) if in_subject.present?
    self.in_body      = NKF.nkf('-Ww --no-best-fit-chars', in_body) if in_body.present?
    self.in_html_body = NKF.nkf('-Ww --no-best-fit-chars', in_html_body) if in_html_body.present?

    if in_files.present?
      in_files.each do |file|
        attach = Gw::WebmailMailAttachment.new(tmp_id: tmp_id)
        if attach.save_file(file)
          @tmp_attachment_ids ||= []
          @tmp_attachment_ids << attach.id
        else
          attach.errors.full_messages.each do |msg|
            errors.add(:base, "#{file.original_filename.force_encoding('UTF-8')}: #{msg}")
          end
        end
      end
    end

    return if mode == :file

    self.in_subject = "件名なし" if in_subject.blank?
    #errors.add :base, "件名が未入力です。"   if in_subject.blank?
    errors.add :base, "件名は100文字以内で入力してください。" if in_subject.size > 100
    errors.add :base, "宛先は150件以内で入力してください。" if @in_to_addrs.size > 150
    errors.add :base, "Ccは150件以内で入力してください。"   if @in_cc_addrs.size > 150
    errors.add :base, "Bccは150件以内で入力してください。"  if @in_bcc_addrs.size > 150

    tmp_attachments.each do |f|
      errors.add :base, "添付ファイルが見つかりません。（#{f.name}）" unless File.exist?(f.upload_path)
    end

    if mode == :send
      errors.add :base, "送信元が未入力です。" if in_from.blank?
      errors.add :base, "宛先が未入力です。"   if in_to.blank? && in_cc.blank? && in_bcc.blank?
      if in_format == FORMAT_HTML
        body_check = in_html_body.present?
      else
        body_check = in_body.present?
      end
      errors.add :base, "本文が未入力です。" unless body_check
    end
    return errors.size == 0
  end

  def init_for_new(template: nil, sign: nil)
    self.tmp_id = Sys::File.new_tmp_id
    if template
      self.in_to      = template.to
      self.in_cc      = template.cc
      self.in_bcc     = template.bcc
      self.in_subject = template.subject
      self.in_body    = template.body
    end
    if sign
      self.in_body = "\n\n#{sign.body}"
    end
    self.in_format = FORMAT_TEXT 
  end

  def init_for_edit(ref, format:)
    self.tmp_id     = Sys::File.new_tmp_id
    self.in_to      = ref.friendly_to_addrs.join(', ')
    self.in_cc      = ref.friendly_cc_addrs.join(', ')
    self.in_bcc     = ref.friendly_bcc_addrs.join(', ')
    self.in_subject = ref.subject
    if format == FORMAT_HTML && ref.html_mail?
      self.in_html_body = ref.html_body_for_edit
      self.in_format    = FORMAT_HTML         
    else
      self.in_body      = ref.text_body
      self.in_format    = FORMAT_TEXT     
    end
    self.in_request_mdn = '1' if ref.has_disposition_notification_to?

    init_tmp_attachments_from_ref(ref)
  end

  def init_for_answer(ref, format:, sign: nil, sign_pos: nil, all: nil, quote: nil)
    self.tmp_id     = Sys::File.new_tmp_id
    self.in_to      = ref.friendly_reply_to_addrs(all.present?).join(', ')
    self.in_cc      = ref.friendly_cc_addrs.join(', ') if all
    self.in_subject = "Re: #{ref.subject}"

    if format == FORMAT_HTML && ref.html_mail?
      quot_body = "<p></p>#{ref.referenced_html_body}" if quote
      sign_body = Util::String.text_to_html("\n" + sign.body) if sign
      self.in_html_body = concat_body_and_sign(quot_body, sign_body, sign_pos)
      self.in_format = FORMAT_HTML
    else
      quot_body = "\n\n#{ref.referenced_body}" if quote
      sign_body = "\n\n#{sign.body}" if sign
      self.in_body = concat_body_and_sign(quot_body, sign_body, sign_pos)
      self.in_format = FORMAT_TEXT
    end
  end

  def init_for_forward(ref, format:, sign: nil, sign_pos: nil)
    self.tmp_id      = Sys::File.new_tmp_id
    self.in_subject  = "Fw: #{ref.subject}"

    if format == FORMAT_HTML && ref.html_mail?
      quot_body = "<p></p>#{ref.referenced_html_body(:forward)}"
      sign_body = Util::String.text_to_html("\n" + sign.body) if sign  
      self.in_html_body = concat_body_and_sign(quot_body, sign_body, sign_pos)
      self.in_format = FORMAT_HTML    
    else
      quot_body = "\n\n#{ref.referenced_body(:forward)}"
      sign_body = "\n\n#{sign.body}" if sign
      self.in_body = concat_body_and_sign(quot_body, sign_body, sign_pos)
      self.in_format = FORMAT_TEXT
    end

    init_tmp_attachments_from_ref(ref)
  end

  def init_tmp_attachments_from_ref(ref)
    self.tmp_attachment_ids = []
    ref.attachments.each do |f|
      file = Gw::WebmailMailAttachment.new(tmp_id: tmp_id)
      tmpfile = Sys::Lib::File::Tempfile.new(data: f.body, filename: f.name)
      file.save_file(tmpfile)
      self.tmp_attachment_ids << file.id
    end
  end

  def concat_body_and_sign(quot_body, sign_body, sign_pos)
    if sign_pos.blank?
      "#{sign_body}#{quot_body}"
    else
      "#{quot_body}#{sign_body}"
    end
  end

  def init_from_flash(flash = {})
    self.in_to  = flash[:mail_to] if flash[:mail_to]
    self.in_cc  = flash[:mail_cc] if flash[:mail_cc]
    self.in_bcc = flash[:mail_bcc] if flash[:mail_bcc]
    self.in_subject = flash[:mail_subject] if flash[:mail_subject]
    self.in_body = flash[:mail_body] if flash[:mail_body]
    self.tmp_id = flash[:mail_tmp_id] if flash[:mail_tmp_id]
    self.tmp_attachment_ids = flash[:mail_tmp_attachment_ids] if flash[:mail_tmp_attachment_ids]
  end

  def init_from_params(params = {})
    self.in_to      = NKF::nkf('-w', params[:to]) if params[:to]
    self.in_cc      = NKF::nkf('-w', params[:cc]) if params[:cc]
    self.in_bcc     = NKF::nkf('-w', params[:bcc]) if params[:bcc]
    self.in_subject = NKF::nkf('-w', params[:subject]) if params[:subject]
    self.in_body    = "#{NKF::nkf('-w', params[:body])}\n\n#{in_body}" if params[:body]
  end

  def prepare_mail(request = nil)
    mail = Mail.new
    mail.charset     = charset
    mail.from        = @in_from_addr[0]
    mail.to          = @in_to_addrs.join(', ')
    mail.cc          = @in_cc_addrs.join(', ')
    mail.bcc         = @in_bcc_addrs.join(', ')
    mail.subject     = in_subject.gsub(/\r\n|\n/, ' ')
    #mail.body    = in_body

    mail.header["X-Mailer"] = "Joruri Mail ver. #{Joruri.version}"
    mail.header["User-Agent"] = request.user_agent.force_encoding('us-ascii') if request
    mail.header["Disposition-Notification-To"] = @in_from_addr[0].to_s if in_request_mdn == '1'

    if @reference ## for answer
      references = []
      case value = @reference.mail.references
      when String
        references << value
      when Array
        references += value
      when ActiveSupport::Multibyte::Chars
        value.to_s.scan(/<([^>]+)>/) {|m| references << m[0] }
      end
      references << @reference.mail.message_id if @reference.mail.message_id
      mail.references("<#{references.join('> <')}>") if references.size > 0
    end

    if tmp_attachments.size == 0
      if self.in_format == FORMAT_HTML
        mail.html_part = make_html_part(self.in_html_body)
        mail.text_part = make_text_part(self.in_body)
      else
        #mail.body = encode_text_body(self.in_body)
        mail.body = self.in_body
      end
    else
      if self.in_format == FORMAT_HTML
        alt_part = Mail::Part.new
        alt_part.content_type "multipart/alternative"
        alt_part.add_part(make_html_part(self.in_html_body))
        alt_part.add_part(make_text_part(self.in_body))
        mail.add_part(alt_part)
      else
        mail.text_part = make_text_part(self.in_body)
      end
      tmp_attachments.each do |f|
        name = f.name
        name = NKF.nkf('-WjM', name).split.join if charset.downcase == 'iso-2022-jp'
        name = NKF.nkf('-WwM', name).split.join if charset.downcase == 'utf-8'
        mail.attachments[name] = {
          content: [f.read].pack('m'),
          content_type: %Q(#{f.mime_type}; name="#{name}"),
          encoding: 'base64'
        }
      end
    end
    mail
  end

  def mdn_request_mode
    return unless has_disposition_notification_to?

    @mdn_request_mode ||=
      if (domain = Core.config['mail_domain']).present? &&
         (addrs = disposition_notification_to_addrs) &&
         addrs[0] && addrs[0].address =~ /[@\.]#{Regexp.escape(domain)}$/i
        :auto
      else
        :manual
      end
  end

  def prepare_mdn(original, send_mode = 'manual', request = nil)
    mail = Mail.new    
    mail.charset = charset
    from = Email.parse_list(in_from)[0]
    mail.from = from
    mail.to = original.disposition_notification_to_addrs[0]
    mail.subject = "開封済み : #{original.subject.gsub(/\r\n|\n/, ' ')}"
    mail.content_type = "multipart/report; report-type=disposition-notification"
    mail.header["X-Mailer"]  = "Joruri Mail ver. #{Joruri.version}"
    mail.header["User-Agent"] = request.user_agent.force_encoding('us-ascii') if request

    #第１パート
    body1 = "次のユーザーに送信されたメッセージの開封確認です:\r\n" +
      "#{original.friendly_from_addr} : #{original.date('%Y/%m/%d %H:%M')}\r\n\r\n" +
      "メッセージが、次の時間に開封されました : #{Time.now.strftime('%Y/%m/%d %H:%M')}"
    mail.text_part = make_text_part(body1)

    #第２パート
    original_recipient = original.mail.header['original-recipient']
    if send_mode == 'auto'
      mode = 'automatically'
    else
      mode = 'manually'
    end
    body2 = "Reporting-UA: #{mail.header["X-Mailer"]}\r\n"
    body2 += "Original-Recipient: #{original_recipient.value}" if original_recipient
    body2 += "Final-Recipient: rfc822; #{from.address}\r\n"
    body2 += "Original-Message-ID: <#{original.mail.message_id}>\r\n" if original.mail.message_id 
    body2 += "Disposition: manual-action/MDN-sent-#{mode}; displayed\r\n"

    part2 = Mail::Part.new
    part2.content_type = %Q(message/disposition-notification; name="ReportPart2.txt")
    part2.content_disposition = "inline"
    #part2.content_transfer_encoding = "7bit"
    part2.body = body2
    mail.add_part part2

    #第３パート
    part3 = Mail::Part.new
    part3.content_type = %Q(text/rfc822-headers; name="ReportPart3.txt")
    part3.content_disposition = "inline"
    #part3.content_transfer_encoding = "7bit"
    part3.body = original.mail.header.raw_source
    mail.add_part part3

    mail
  end

  def for_save
    return nil unless @mail
    @mail.header[:bcc].include_in_headers = true
    @mail  
  end

  def zip_attachments(encoding: 'utf-8')
    filenames = attachments.map do |at|
      name = at.name
      name = name.encode(Encoding::Windows_31J, invalid: :replace, undef: :replace, replace: '_') if encoding == 'shift_jis'
      name = Util::File.filesystemize(name, byte_size: 250, keep_ext: true)
      name
    end
    filenames = Util::File.unique_filenames(filenames)

    data = ""
    Zip::Archive.open_buffer(data, Zip::CREATE, Zip::NO_COMPRESSION) do |ar|
      attachments.each_with_index do |at, i|
        begin
          ar.add_buffer(filenames[i], at.body)
        rescue Zip::Error => e
          # e
        end
      end
    end
    data
  end

  private

  def modify_html_body(html, charset = 'utf-8')
    html =
      %Q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">) +
      %Q(<html><head>) +
      %Q(<meta http-equiv="content-type" content="text/html; charset=UTF-8">) +
      %Q(<link rel="stylesheet" media="all" href="file://#{Rails.root.join('public/_common/js/tiny_mce_config/content_html_mail.css')}" />) +
      %Q(</head><body>#{html}</body></html>)
    pm = Premailer.new(html, with_html_string: true, input_encoding: 'utf-8', adapter: :hpricot)
    pm.to_inline_css.sub(/charset=UTF-8/i, "charset=#{charset}")
  end

  def make_html_part(body)
    part = Mail::Part.new
    part.content_type %Q(text/html; charset="#{charset}")
    part.body encode_text_body(modify_html_body(body, charset))
    part
  end

  def make_text_part(body)
    part = Mail::Part.new
    part.content_type %Q(text/plain; charset="#{charset}")
    part.body encode_text_body(body)
    part
  end

  def encode_text_body(body)
    return NKF.nkf("-Wj", body).force_encoding('us-ascii') if charset.downcase == 'iso-2022-jp'
    body
  end

  class << self
    def make_conditions_from_params(params, fromto = 'FROM')
      conds =  ['UNDELETED']
      conds += ['UNSEEN'] if params[:s_status] == 'unseen'
      conds += ['SEEN']   if params[:s_status] == 'seen'
      conds += ['KEYWORD', "$label#{params[:s_label]}"] if params[:s_label].present?
      conds += ['FLAGGED']   if params[:s_flag] == 'starred'
      conds += ['UNFLAGGED'] if params[:s_flag] == 'unstarred'

      if params[:s_column].present? && params[:s_keyword].present?
        params[:s_keyword].split(/[ 　]+/).each do |w|
          next if w.blank?
          conds += [params[:s_column].upcase, Net::IMAP::QuotedString.new(w)] 
        end
      end
      if params[:s_from]
        if from_addr = Email.parse(params[:s_from]).try(:address)
          conds += [fromto, Net::IMAP::QuotedString.new(from_addr)]
        end
      end
      conds
    end

    def make_sort_from_params(params)
      key, order = params[:sort_key].present? ? [params[:sort_key], params[:sort_order]] : ['date', 'reverse']

      sorts = []
      sorts += [order.upcase] if order.present?
      sorts += [key.upcase]
      sorts += ['REVERSE', 'DATE'] if key != 'date'
      sorts
    end

    def load_from_cache(mailbox, uids)
      nodes = Gw::WebmailMailNode.where(user_id: Core.current_user.id, mailbox: mailbox, uid: uids).all
      return [] if nodes.blank?

      msgs = imap.uid_fetch(nodes.map(&:uid), ['UID', 'FLAGS']).to_a
      msgs = msgs.map { |msg| [msg.attr['UID'], msg.attr['FLAGS']] }.flatten(1)
      flags = Hash[*msgs]
      nodes.map do |node|
        item = self.new(node)
        item.flags = flags[node.uid]
        item
      end
    end

    def fetch(uids, mailbox, use_cache: true)
      uids = Array(uids)
      return [] if uids.blank?

      imap.examine(mailbox)

      # load from db cache
      if use_cache
        items = load_from_cache(mailbox, uids)
        fetch_uids = uids - items.map(&:uid)
        return items if fetch_uids.blank?
      else
        items = []
        fetch_uids = uids
      end

      # load from imap
      header_fields = 'HEADER.FIELDS (DATE FROM TO CC BCC SUBJECT CONTENT-TYPE CONTENT-DISPOSITION DISPOSITION-NOTIFICATION-TO)'
      fields = ['UID', 'FLAGS', 'RFC822.SIZE', "BODY.PEEK[#{header_fields}]"]
      fields += ['X-MAILBOX', 'X-REAL-UID'] if mailbox =~ /^virtual/
      imap.uid_fetch(fetch_uids, fields).to_a.each do |msg|
        item = self.new(msg.attr["BODY[#{header_fields}]"])
        item.uid        = msg.attr['UID'].to_i
        item.mailbox    = mailbox
        item.size       = msg.attr['RFC822.SIZE']
        item.flags      = msg.attr['FLAGS']
        item.x_mailbox  = msg.attr['X-MAILBOX']
        item.x_real_uid = msg.attr['X-REAL-UID']
        items << item
      end

      # save db cache
      if use_cache
        nodes = []
        items.each do |item|
          next unless fetch_uids.include?(item.uid)
          nodes << Gw::WebmailMailNode.new do |n|
            n.user_id          = Core.current_user.id
            n.uid              = item.uid
            n.mailbox          = mailbox
            n.message_date     = item.date
            n.from             = item.friendly_from_addr
            n.to               = item.friendly_to_addrs.join("\n")
            n.cc               = item.friendly_cc_addrs.join("\n")
            n.bcc              = item.friendly_bcc_addrs.join("\n")
            n.subject          = item.subject
            n.has_attachments  = item.has_attachments?
            n.size             = item.size
            n.has_disposition_notification_to = item.has_disposition_notification_to?
            if mailbox =~ /^virtual/
              n.ref_mailbox = item.x_mailbox
              n.ref_uid     = item.x_real_uid
            end
          end
        end
        Gw::WebmailMailNode.import(nodes)
      end

      items
    end

    def fetch_for_filter(uids, mailbox, options = {})
      uids = Array(uids)
      return [] if uids.blank?

      imap.examine(mailbox)

      fields = ['UID', 'BODY.PEEK[HEADER.FIELDS (FROM TO SUBJECT)]']
      imap.uid_fetch(uids, fields).to_a.map do |msg|
        item = self.new(msg.attr['BODY[HEADER.FIELDS (FROM TO SUBJECT)]'])
        item.uid     = msg.attr['UID'].to_i
        item.mailbox = mailbox
        item
      end
    end

    private

    def encode_body_structure(struct, lv)
      return "" if !struct || lv > 5

      msg = ""
      if lv != 0 && struct.media_type && struct.subtype
        msg += "Content-Type: #{struct.media_type.downcase}/#{struct.subtype.downcase}"
        msg += ";" unless struct.param
        msg += "\r\n"
        if struct.param
          struct.param.each_with_index do |(key, value), index|
            if key == "BOUNDARY" || key == "NAME"
              msg += " #{key.downcase}=\"#{value}\""
            else
              msg += " #{key.downcase}=#{value}"
            end
            msg += ";" if index != struct.param.size - 1
            msg += "\r\n"
          end
          msg += "\r\n"
        end
      end
      if struct.multipart? && struct.parts && struct.param
        boundary = struct.param["BOUNDARY"]
        struct.parts.each do |part|
          msg += "--#{boundary}\r\n"
          msg += encode_body_structure(part, lv + 1)
          msg += "\r\n"
        end
        msg += "--#{boundary}--\r\n\r\n"
      end
      msg
    end
  end
end
