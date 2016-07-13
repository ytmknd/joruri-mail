module Gw::MailHelper
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
    from_tooltip = truncate(mail.subject, length: 70, escape: false)
    from, from_tooltip = omit_from_address_in_mail_list(from) if omit
    return from, s_from, from_tooltip
  end

  def mail_mdn_dipslay?(mail, mailbox)
    if mailbox.draft_box? || mailbox.sent_box?
      mail.has_disposition_notification_to?
    else
      mail.has_disposition_notification_to? && mail.notified?
    end
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

  def recent_maintenance
    Sys::Maintenance.state_public.order(published_at: :desc).first
  end

  def mail_form_style
    @mail_form_size = Gw::WebmailSetting.user_config_value(:mail_form_size, 'medium') unless @mail_form_size
    "resizable=yes,scrollbars=yes,width=#{mail_form_size(@mail_form_size)[:window]}"
  end

  def open_mail_form(uri)
    uri = escape_javascript(uri)
    "openMailForm('#{uri}', '#{mail_form_style}');return false;"
  end

  def mail_form_size(size_name)
    rtn = {
      'small'  => { window: 800, container: 770, textarea: 675 },
      'medium' => { window: 900, container: 870, textarea: 775 },
      'large'  => { window: 1000, container: 970, textarea: 875 }
    }[size_name]
    rtn = {} unless rtn
    rtn
  end

  def mail_text_wrap(text, col = 1, options = {})
    to_nbsp = lambda do |txt|
      txt.gsub(/(^|\t| ) +/) {|m| m.gsub(' ', '&nbsp;')}
    end

    text = "#{text}".force_encoding('utf-8')
    text = text.gsub(/\t/, "  ")
    text = text_wrap(text, col, "\t") unless request.env['HTTP_USER_AGENT'] =~ /(MSIE|Trident)/
    if options[:auto_link]
      text = mail_text_autolink(text)
      text = to_nbsp.call(text)
    else
      text = h(text)
      text = to_nbsp.call(text)
    end
    text = text.gsub(/\t/, '<wbr></wbr>')
    br(text)
  rescue => e
    #error_log("#{e}: #{text}")
    "#read failed: #{e}"
  end

  def mail_text_autolink(text)
    http_pattern = 'h\t?t\t?t\t?p\t?s?\t?:\t?\/\t?\/[a-zA-Z0-9_\.\/~%:#\?=&;\-@\+\$,!\*\'\(\)\t]+'
    mail_pattern = '\w\t?[\w\._\-\+\t]*@[\w\._\-\+\t]+'

    target = text
    text = ''.html_safe
    while target && match = target.match(/(#{http_pattern})|(#{mail_pattern})/i)
      if match[1]
        text << h(target[0, match.begin(1)])
        text << link_to(match[1], match[1].gsub("\t", ''), target: '_blank')
        target = target[match.end(1), target.size]
      elsif match[2]
        text << h(target[0, match.begin(2)])
        addr = match[2].gsub("\t", '')
        uri = new_gw_webmail_mail_path(to: addr)
        text << link_to(match[2], uri, onclick: open_mail_form(uri))
        target = target[match.end(2), target.size]
      end
    end
    text << h(target) if target
  end

  def mail_html_autolink(html)
    autolink_for_text = lambda do |text|
      ret = ''
      text = CGI::unescapeHTML(text)
      while text && match = text.match(/(&[a-zA-Z0-9#]+;)/i) do
        if match[1]
          ret << mail_text_autolink(text[0, match.begin(1)])
          ret << match[1]
          text = text[match.end(1), text.size]
        end
      end
      ret << mail_text_autolink(text) if text
    end

    ret = ''
    target = html
    while target && match = target.match(/>([^<]+)</im) do
      if match[1]
        ret << target[0, match.begin(1)]
        ret << autolink_for_text.call(match[1])
        target = target[match.end(1), target.size]
      end
    end
    ret << target if target
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
        from = link_to(from, new_gw_webmail_mail_path(to: to))
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
    [ /(MSIE) (\d+)\.(\d*)/,
      /(Trident).+rv:(\d+)\.(\d*)/,
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
    limit_size = 1024**3
    agent, version, subversion = user_agent_info(request.user_agent)

    case agent
    when 'MSIE'
      if version < 8
        limit_size = 0
      elsif version == 8
        limit_size = 32*1024
      end
    when 'Firefox'
      if version < 2
        limit_size = 0
      elsif version == 2
        limit_size = 100*1024
      end
    when 'Opera'
      if version < 7
        limit_size = 0 
      elsif version == 7 && subversion < 20
        limit_size = 4*1024
      end
    when 'Chrome', 'Safari', 'Trident'
    else
      limit_size = 0
    end
    return limit_size
  end

  def thumbnail_for_embed(at, options)
    limit_size = data_uri_scheme_limit_size

    if limit_size > 0 && (thumbnail = at.thumbnail(width: options[:width] || 128, height: options[:height] || 96, format: :JPEG, quality: 70))
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
      'gw/admin/webmail/mails/form/file_flash'
    else
      'gw/admin/webmail/mails/form/file'
    end
  end
end
