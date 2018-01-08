module Webmail::MailHelper
  def mail_flags(mail)
    flags = []
    flags << 'answered' if mail.answered?
    flags << 'forwarded' if mail.forwarded?
    flags << 'mdnRequest' if mail.has_disposition_notification_to?
    flags
  end

  def mail_from_display(mail, mailbox, omit = false)
    if mailbox.draft_box? || mailbox.sent_box?
      from = mail.simple_to_addr
      s_from = mail.friendly_to_addrs[0] || ''
    else
      from = mail.friendly_from_addr
      s_from = mail.friendly_from_addr
    end
    from_tooltip = truncate(mail.subject, length: 70, escape: true)
    from, from_tooltip = omit_from_address_in_mail_list(from) if omit
    return from, s_from, from_tooltip
  end

  def mail_mdn_dipslay?(mail, mailbox)
    if mailbox.draft_box? || mailbox.sent_box?
      mail.has_disposition_notification_to?
    else
      mail.has_disposition_notification_to? && mail.mdn_sent?
    end
  end

  def mail_priority_label(mail)
    I18n.t('enumerize.webmail/mail.priority_label')[mail.priority.to_sym]
  end

  def mail_priority_title(mail)
    I18n.t('enumerize.webmail/mail.priority_title')[mail.priority.to_sym]
  end

  def mail_short_date(mail)
    if mail.date && (match = mail.date.match(/\d{4}-(\d{2})-(\d{2})\s*\d{2}:\d{2}/))
      "#{match[1]}/#{match[2]}"
    else
      mail.date
    end
  end

  def mail_star_image_path(mail)
    if mail.starred?
      "/_common/themes/admin/gw/images/mailoption/star_on.gif"
    else
      "/_common/themes/admin/gw/images/mailoption/star_off.gif"
    end
  end

  def mail_form_style
    @mail_form_size ||= Webmail::Setting.user_config_value(:mail_form_size, 'medium')
    "resizable=yes,scrollbars=yes,width=#{mail_form_size(@mail_form_size)[:window]}"
  end

  def open_mail_form(uri)
    uri = escape_javascript(uri)
    "openMailForm('#{uri}', '#{mail_form_style}');return false;"
  end

  def mail_form_size(size_name)
    rtn = {
      'small'  => { window: 850, container: 820, textarea: 725 },
      'medium' => { window: 950, container: 920, textarea: 825 },
      'large'  => { window: 1050, container: 1020, textarea: 925 }
    }[size_name]
    rtn = {} unless rtn
    rtn
  end

  def insert_wbr_tag(text, col)
    text = text.gsub("\t", '  ')
    if !request.mobile? && request.user_agent !~ /MSIE/
      text = text_wrap(text, col, "\t")
      text = html_escape(text).gsub("\t", '<wbr></wbr>')
    end
    text.gsub(' ', '&nbsp;')
  end

  def insert_wbr_tag_with_autolink(text, col)
    text = html_escape(text)
    text = mail_text_autolink(text)

    doc = Nokogiri::HTML.fragment(text)
    doc.xpath('descendant::text()').each do |node|
      next unless node.content
      node.replace(insert_wbr_tag(node.content, col))
    end
    text = doc.to_s

    nbsp = Nokogiri::HTML('&nbsp;').text
    text.gsub(nbsp, '&nbsp;')
  end

  def mail_text_wrap(text, col = 1, options = {})
    return '' if text.blank?
    text =
      if options[:auto_link]
        insert_wbr_tag_with_autolink(text, col)
      else
        insert_wbr_tag(text, col)
      end
    br(text)
  end

  def mail_text_autolink(text)
    auto_link(text, sanitize: false, html: { target: '_blank' })
  rescue => e
    error_log "#{e}\n#{e.backtrace.join("\n")}"
    text
  end

  def mail_html_autolink(html)
    mail_text_autolink(html)
  end

  def omit_from_address_in_mail_list(from)
    return from unless from
    addr = from
    if match = from.match(/^(.+)<(.+)>\s*(他|$)/) || from.match(/^(.+?)(他|$)/)
      from = match[1].strip
      from = "#{from} 他" if match[3] ? match[3].present? : match[2].present? 
      addr = (match[3] ? match[2] : match[1]).strip 
    end
    [from, addr]
  end

  def omit_from_addresses_in_mail_list(froms, options = {})
    froms = froms.map do |from|
      from, addr = omit_from_address_in_mail_list(from)
      if options[:auto_link]
        to = (from == addr ? from : "#{from} <#{addr}>")
        if options[:wrap]
          from = mail_text_wrap(from)
        end
        to = to.encode(request.mobile.default_charset, invalid: :replace, undef: :replace, replace: ' ') if request.mobile?
        from = link_to(from, new_webmail_mail_path(to: to))
      end
      from
    end
    froms.join(", ")
  end

  def extract_address_from_mail_list(from)
    if from.match(/<(.+)>/)
      from = $1
    end
    from
  end

  def extract_addresses_from_mail_list(froms)
    froms ||= ""
    froms.split(/,/).map do |from|
      extract_address_from_mail_list(from)
    end
  end

  def user_agent_info(user_agent)
    [ /(Trident)\/(\d+)\.(\d*)/,
      /(MSIE) (\d+)\.(\d*)/,
      /(Firefox)\/(\d+)\.(\d*)/,
      /(?=.*(Opera)[\s|\/])(?=.*Version\/(\d+)\.(\d*))/,
      /(Chrome)\/(\d+)\.(\d*)/,
      /(?=.*(Safari)\/)(?=.*Version\/(\d+)\.(\d*))/
    ].each do |regexp|
      if user_agent =~ regexp
        return $1, $2.to_i, $3.to_i
      end
    end
    return "unknown"
  end

  def data_uri_scheme_limit_size
    agent, version, subversion = user_agent_info(request.user_agent)

    max_size = 1024**3
    case agent
    when 'Trident'
      if version < 4
        0
      elsif version == 4 # same as IE8
        32*1024
      else
        max_size
      end
    when 'MSIE'
      if version < 8
        0
      elsif version == 8
        32*1024
      else
        max_size
      end
    when 'Firefox'
      if version < 2
        0
      elsif version == 2
        100*1024
      else
        max_size
      end
    when 'Opera'
      if version < 7
        0
      elsif version == 7 && subversion < 20
        4*1024
      else
        max_size
      end
    when 'Chrome', 'Safari'
      max_size
    else
      0
    end
  end

  def attachment_thumbnail_options
    {
      width: Joruri.config.application['webmail.thumbnail_width'],
      height: Joruri.config.application['webmail.thumbnail_height'],
      format: 'jpeg',
      quality: Joruri.config.application['webmail.thumbnail_quality'],
      method: Joruri.config.application['webmail.thumbnail_method']
    }
  end

  def attachment_thumbnail_for_embed(at)
    limit_size = data_uri_scheme_limit_size

    if limit_size > 0 && (thumbnail = at.thumbnail(attachment_thumbnail_options))
      thumbnail = Base64.encode64(thumbnail)
      if thumbnail.length <= limit_size
        return thumbnail
      end
    end
    return nil
  end

  def mail_form_download_message
    if attachment_file_downloadable?
      I18n.t('webmail.helpers.download_allow_message_html')
    else
      I18n.t('webmail.helpers.download_deny_message_html')
    end
  end

  def attachment_file_downloadable?
    ips = Joruri.config.application['webmail.attachment_file_downloadable_ips']
    key = Joruri.config.application['webmail.remote_ip_key']
    return true if ips.nil?

    ips.include?(request.env[key].to_s.split(',').last.to_s.strip)
  end

  def mail_form_file_uploader_path
    case Joruri.config.application['webmail.attachment_file_upload_method']
    when 'flash'
      'webmail/admin/mails/form/file_flash'
    else
      'webmail/admin/mails/form/file'
    end
  end

  def mail_form_action
    action = params.dig(:mobile, :action) || action_name
    case action
    when 'new', 'create' then 'create'
    when 'edit', 'update' then 'update'
    when 'answer' then 'answer'
    when 'forward' then 'forward'
    end
  end

  def mail_form_method
    action = params.dig(:mobile, :action) || action_name
    case action
    when 'edit', 'update' then 'patch'
    else 'post'
    end
  end

  def mail_form_url(mail, options = {})
    options = options.merge(mailbox: mail.x_mailbox, id: mail.x_real_uid) if mail.x_mailbox.present?
    url_for(options)
  end
end
