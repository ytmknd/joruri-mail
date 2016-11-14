module Util::String
  def self.search_platform_dependent_characters(str)
    regex = "[" +
      "①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳" +
      "ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ㍉㌔㌢㍍㌘㌧㌃㌶㍑㍗" +
      "㌍㌦㌣㌫㍊㌻㎜㎝㎞㎎㎏㏄㎡㍻〝〟№㏍℡㊤" +
      "㊥㊦㊧㊨㈱㈲㈹㍾㍽㍼㍻©®㈷㈰㈪㈫㈬㈭㈮㈯" +
      "㊗㊐㊊㊋㊌㊍㊎㊏㋀㋁㋂㋃㋄㋅㋆㋇㋈㋉㋊㋋" +
      "㏠㏡㏢㏣㏤㏥㏦㏧㏨㏩㏪㏫㏬㏭㏮㏯㏰㏱㏲㏳" +
      "㏴㏵㏶㏷㏸㏹㏺㏻㏼㏽㏾↔↕↖↗↘↙⇒⇔⇐⇑⇓⇕⇖⇗⇘⇙" +
      "㋐㋑㋒㋓㋔㋕㋖㋗㋘㋙㊑㊒㊓㊔㊕㊟㊚㊛㊜㊣" +
      "㊡㊢㊫㊬㊭㊮㊯㊰㊞㊖㊩㊝㊘㊙㊪㈳㈴㈵㈶㈸" +
      "㈺㈻㈼㈽㈾㈿►☺◄☻‼㎀㎁㎂㎃㎄㎈㎉㎊㎋㎌㎍" +
      "㎑㎒㎓ⅰⅱⅲⅳⅴⅵⅶⅷⅸⅹ〠♠♣♥♤♧♡￤＇＂" +
      "]"
    
    chars = []
    if str =~ /#{regex}/
      str.scan(/#{regex}/).each do |c|
        chars << c
      end
    end
    
    chars.size == 0 ? nil : chars.uniq.join('')
  end
  
  def self.text_to_html(text)
    rslt = ''
    text.each_line do |line|
      line.chomp!
      line.gsub!(/&/, '&amp;')
      line.gsub!(/</, '&lt;')
      line.gsub!(/>/, '&gt;')
      line.gsub!(/(\s+)\s/) do |m|
        '&nbsp;' * m.length
      end
      #line << '&nbsp;' if line.blank?
      rslt << %Q(<p>#{line}</p>\n)
    end
    rslt
  end

  def self.encode_utf8mb4(str)
    str.gsub(/[^\u{0}-\u{FFFF}]/) { '&#x%X;' % $&.ord }
  end

  def self.decode_utf8mb4(str)
    str.gsub(/&#(x(([0-9a-fA-F]{5,6}))|\d{5,7});/) {
      (defined?($2) ? $2.to_i(16): $1.to_i(10)).chr('UTF-8')
    }
  end
end
