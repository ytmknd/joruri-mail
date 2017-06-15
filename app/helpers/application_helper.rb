module ApplicationHelper
  ## nl2br
  def br(str)
    str.to_s.gsub(/\r\n|\r|\n/, '<br />').html_safe
  end
  
  ## nl2br and escape
  def hbr(str)
    str = html_escape(str)
    str.gsub(/\r\n|\r|\n/, '<br />').html_safe
  end
  
  ## wrap long string
  def text_wrap(text, col = 80, char = " ")
    #text.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/, "\\1\\3#{char}") 
    #text.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/, "\\1\\2\\3#{char}")
    #text.gsub(/(.{#{col}})( +|$\n?)|(.{#{col}})/, "\\1\\2\\3#{char}")
    text = text.gsub("\r\n", "\n")
    text.gsub(/(.{#{col}})(( *$\n?)| +)|(.{#{col}})/) do |match|
      if $3
        "#{$1}#{$2}"
      else
        "#{$1}#{$2}#{$4}#{char}"
      end
    end
  end
  
  ## safe calling
  def safe(alt = nil, &block)
    begin
      yield
    rescue NoMethodError => e
      # nil判定を追加
      #if e.respond_to? :args and (e.args.nil? or (!e.args.blank? and e.args.first.nil?))
        alt
      #else
        # 原因がnilクラスへのアクセスでない場合は例外スロー
      #  raise
      #end
    end
  end
  
  ## paginates
  def paginate(items, options = {})
    return '' unless items
    defaults = {
      params:         p,
      previous_label: '前のページ',
      next_label:     '次のページ',
      link_separator: '<span class="separator"> | </span>'
    }
    if request.mobile?
      defaults[:page_links]     = false
      defaults[:previous_label] = '&lt;&lt;*前へ'
      defaults[:next_label]     = '次へ#&gt;&gt;'
    end
    links = will_paginate(items, defaults.merge!(options))
    return links if links.blank?
    if Core.request_uri != Core.internal_uri
      links.gsub!(/href="#{URI.encode(Core.internal_uri)}/) do |m|
        m.gsub(/^(href=").*/, '\1' + URI.encode(Core.request_uri))
      end
    end
    if request.mobile?
      links.gsub!(/<a [^>]*?rel="prev( |")/) {|m| m.gsub(/<a /, '<a accesskey="*" ')}
      links.gsub!(/<a [^>]*?rel="next( |")/) {|m| m.gsub(/<a /, '<a accesskey="#" ')}
    end
    links.html_safe
  end

  def content_tag_if(cond, tag, options = {}, &block)
    if cond
      content_tag tag, options do
        capture(&block)
      end
    else
      capture(&block)
    end
  end
end
