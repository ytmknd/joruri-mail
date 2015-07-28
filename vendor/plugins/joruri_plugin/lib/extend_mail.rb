# encoding: utf-8
require 'mail'
require 'mail/field'
require 'mail/fields/common/common_address'

#Mail::UnstructuredField.module_eval do
#  def encode_with_fix(value)
#    encode_without_fix(value.encode(charset))
#  end
#  alias_method_chain :encode, :fix
#end
#
#Mail::Message.module_eval do
#  def charset=(value)
#    @defaulted_charset = false
#    @charset = value
#    @header.charset = value
#    @body.charset   = value
#  end
#end
#
#Mail::Body.module_eval do
#  def encoded_with_fix(transfer_encoding = '8bit')
#    dec = Mail::Encodings::get_encoding(encoding)
#    if multipart? ||  transfer_encoding == encoding and dec.nil?
#      encoded_without_fix(transfer_encoding)
#    else
#      enc = Mail::Encodings::get_encoding(get_best_encoding(transfer_encoding))
#      enc.encode(dec.decode(raw_source).encode(charset))
#    end
#  end
#  alias_method_chain :encoded, :fix
#end

class Mail::DispositionNotificationToField < Mail::StructuredField

    include Mail::CommonAddress
    
    FIELD_NAME = 'disposition-notification-to'
    CAPITALIZED_FIELD = 'Disposition-Notification-To'
    
    def initialize(value = nil, charset = 'utf-8')
      self.charset = charset
      super(CAPITALIZED_FIELD, strip_field(FIELD_NAME, value), charset)
      self.parse
      self
    end
    
    def encoded
      do_encode(CAPITALIZED_FIELD)
    end
    
    def decoded
      do_decode
    end
end

Mail::Message.class_eval do
  def find_attachment
    case
    when content_type && header[:content_type].filename
      filename = header[:content_type].filename
    when content_disposition && header[:content_disposition].filename
      filename = header[:content_disposition].filename
    when content_location && header[:content_location].location
      filename = header[:content_location].location
    else
      filename = nil
    end
    
    if filename
      filename.gsub!(/(=\?)SHIFT-JIS(\?[BQ]\?.+?\?=)/i, '\1' + 'Shift_JIS' +'\2')
      input_charset = nil
      if mt = filename.match(/=\?(.+?)\?[BQ]\?.+?\?=/i)
        input_charset = NKFUtil.input_option(mt[1])
      end
      filename = ::NKF::nkf("-wx --cp932 #{input_charset}", filename)
    end
    filename
  rescue => e
    error_log(e)
    nil
  end
  
  def boundary
    content_type_parameters ? 
      content_type_parameters['boundary'] || 
      content_type_parameters['Boundary'] || 
      content_type_parameters['BOUNDARY'] : nil
  end
end

module Mail
  class JoruriAdjustor
    def self.adjust_quotation(value, param)
      if mt = value.match(/;\s*#{param}=(.*?)(;|$)/im)
        if mt[1].strip[0] != '"'
          value = value[0, mt.begin(1)] + '"' + mt[1].strip + '"' + value[mt.end(1), value.size]
        end
      end
      return value
    end
    
    def self.adjust_encoding(value, param)
      match = value.match(/;\s*#{Regexp.escape(param)}="(.*?)"\s*(;|$)/im)
      return value unless match
      return value if match[1].ascii_only?
      
      enc = NKF.guess(match[1])
      nkf_opt = nil
      nkf_opt = NKFUtil.output_option(enc.name) if enc
      nkf_opt = "-w" unless nkf_opt
      encoded = NKF.nkf("-M #{nkf_opt}", match[1]).gsub("\r\n", "\n").gsub(/\n[ \t]+/, ' ')
      return value[0, match.begin(1)] + encoded + value[match.end(1), value.size]
    end
    
    def self.chop_last_semicolon(value)
      if value[-1] == ';'
        value.gsub!(/;+$/, '')
      end
      return value
    end
    
    def self.adjust_attachment(value)
      if mt = value.match(/^\s*(attachment)(;|$)/im)
        if mt[1].strip[0] != '"'
          value = value[0, mt.begin(1)] + mt[1].downcase + value[mt.end(1), value.size]
        end
      end
      return value
    end
    
    def self.adjust_rfc2231_filename(value)
      target = value
      new_value = ''
      while target && match = target.match(/(filename\*(?:[0-9]+\*?)?=)(.*?)(;|$)/im)
        new_value << target[0, match.begin(0)] << match[1]
        if match[2] =~ /^([^']+'[^']*')?(.+)$/im
          if $1.blank? && $2.strip[0] == '"'
            new_value << $2.strip
          else
            new_value << "#{$1}" << $2.force_encoding('binary').gsub(/[\x00-\x1f\x7f-\xff\s\*'\(\)<>@,;:\\"\/\[\]\?=]/n) {|m|
              sprintf('%%%x', m.ord)
            }              
          end
        end
        new_value << match[3]
        target = target[match.end(0), target.size]
      end
      new_value << target if target
      new_value
    end
    
    def self.adjust_rfc2231_filename_ja(value)
      accept_encoding = 'iso-2022-jp|shift_jis|euc-jp|utf-8'
      if mt = value.match(/;\s*filename\*(?:0\*?)?=(?:#{accept_encoding})'(.*?)'/im)
        if mt[1].blank?
          value = value[0, mt.begin(1)] + 'ja' + value[mt.end(1), value.size]
        end
      end
      return value
    end
    
    def self.adjust_mime_type(value)
      if mt = value.match(/^(.*?);/im)
        if mt[1].blank? || mt[1] !~ /[^\/]+\/[^\/]+/
          value = value[0, mt.begin(1)] + 'application/unknown' + value[mt.end(1), value.size]
        end
      end
      return value
    end
  end

  class ContentDispositionElement # :nodoc:
    def initialize( string )
      string = JoruriAdjustor.chop_last_semicolon(string)
      string = JoruriAdjustor.adjust_attachment(string)
      string = JoruriAdjustor.adjust_quotation(string, "filename")
      string = JoruriAdjustor.adjust_encoding(string, "filename")
      string = JoruriAdjustor.adjust_rfc2231_filename(string)
      string = JoruriAdjustor.adjust_rfc2231_filename_ja(string)
      parser = Mail::ContentDispositionParser.new
      parser.consume_all_input = false
      if tree = parser.parse(cleaned(string))
        @disposition_type = tree.disposition_type.text_value
        @parameters = tree.parameters
      else
        @disposition_type = ""
        @parameters = [{}]
      #else
      #  raise Mail::Field::ParseError, "ContentDispositionElement can not parse |#{string}|\nReason was: #{parser.failure_reason}\n"
      end
      #if parser.failure_index != string.size
      #  error_log("ContentDispositionElement can not parse |#{string}|\nReason was: #{parser.failure_reason}\n")
      #end
    end
  end
  
  class ContentTypeElement # :nodoc:
    def initialize( string )
      string = JoruriAdjustor.adjust_quotation(string, "name")
      string = JoruriAdjustor.adjust_encoding(string, "name")
      string = JoruriAdjustor.adjust_mime_type(string)
      parser = Mail::ContentTypeParser.new
      parser.consume_all_input = false
      if tree = parser.parse(cleaned(string))
        @main_type = tree.main_type.text_value.downcase
        @sub_type = tree.sub_type.text_value.downcase
        @parameters = tree.parameters
      else
        @main_type = ""
        @sub_type = ""
        @parameters = [{}]
      #else
      #  raise Mail::Field::ParseError, "ContentTypeElement can not parse |#{string}|\nReason was: #{parser.failure_reason}\n"
      end
      #if parser.failure_index != string.size && (@main_type.empty? || @sub_type.empty?)
      #  error_log("ContentTypeElement can not parse |#{string}|\nReason was: #{parser.failure_reason}\n")
      #end
    end
  end
  
  class ContentDispositionField < StructuredField
    def filename
      case
      when parameters['filename*']
        @filename = parameters['filename*'].dup.force_encoding('utf-8')
      when parameters['filename']
        @filename = parameters['filename'].dup.force_encoding('utf-8')
      when parameters['name']
        @filename = parameters['name'].dup.force_encoding('utf-8')
      else
        @filename = nil
      end
      @filename
    end
  end
  
  class Body
    def split!(boundary)
      self.boundary = boundary
      parts = raw_source.split("--#{boundary}")
      # Make the preamble equal to the preamble (if any)
      self.preamble = parts[0].to_s.strip
      # Make the epilogue equal to the epilogue (if any)
      self.epilogue = parts[-1].to_s.sub(/^--/, '').strip
      parts[1...-1].to_a.each { |part| @parts << Mail::Part.new(part) }
      unless self.epilogue.empty?
        @parts << Mail::Part.new(self.epilogue)
        self.epilogue = ""
      end
      self
    end
  end
end

if Util::Config.load(:core)['mail_domain'] == 'demo.joruri.org'
  
  Mail::Message.class_eval do |cls|
  
    def delivery_handler
      cls = Class.new do
        
        def initialize
          @domain = Core.config['mail_domain']
        end
        
        def filter(f)
          return f.addrs if @domain.blank?
          filtered = []
          f.each do |addr|
            filtered << addr if addr.address =~ /[@\.]#{Regexp.escape(@domain)}$/i
          end
          filtered        
        end
        
        def deliver_mail(m)
                  
          to = m.header[:to]
          cc = m.header[:cc]
          bcc = m.header[:bcc]
          m.to = filter(to).join(',') if to
          m.cc = filter(cc).join(',') if cc
          m.bcc = filter(bcc).join(',') if bcc
          
          yield        
        end
      end
      cls.new
    end
  end
end

class Mail::ContentTypeField
  unless method_defined? :xxx_parameters
    alias xxx_parameters parameters
  end
  def parameters
    if xxx_parameters.key?("boundary")
      xxx_parameters.delete("charset")
    end
    xxx_parameters
  end
end
