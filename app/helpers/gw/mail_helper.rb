module Gw::MailHelper

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
    @from_address_pattern1_in_mail_list ||= /^(.+)<(.+)>\s*(他|$)/
    @from_address_pattern2_in_mail_list ||= /^(.+?)(他|$)/
    addr = from
    match = from.match(@from_address_pattern1_in_mail_list) || from.match(@from_address_pattern2_in_mail_list)
    if match
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

  def candidate_mail_list_limit
      [[20, 20], [30, 30], [40, 40], [50, 50]]
  end

  def mailbox_mobile_image_tag(mailbox_type, options = {})
    postfix = "-blue" if options[:blue]
    case mailbox_type
    when 'inbox'
      %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/transmit#{postfix}.jpg" alt="受信トレイ" />}
    when 'drafts'
      %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/draft#{postfix}.jpg" alt="下書き" />}
    when 'sent'
      %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/mailbox#{postfix}.jpg" alt="送信トレイ" />}
    when 'archives'
      %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/archive#{postfix}.jpg" alt="アーカイブ" />}
    when 'trash'
      %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/dustbox#{postfix}.jpg" alt="ごみ箱" />}
    when 'arvhives'
      %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/archive#{postfix}.jpg" alt="アーカイブ" />}
    when 'star'
      %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/star#{postfix}.jpg" alt="スター付き" />}
    when 'folder'
      %Q{∟}
    else
      %Q{<img alt="フォルダ" src="/_common/themes/admin/gw/webmail/mobile/images/folder-white.jpg" alt="フォルダ" />}
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

  def attachment_file_downloadable?
    ips = Joruri.config.application['webmail.attachment_file_downloadable_ips']
    key = Joruri.config.application['webmail.remote_ip_key']
    return true if ips.nil?

    ips.include?(request.env[key].to_s.split(',').last.to_s.strip)
  end
end
