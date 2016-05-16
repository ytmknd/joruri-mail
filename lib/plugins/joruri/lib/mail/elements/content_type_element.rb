module Mail
  module ContentTypeElementFix
    def initialize( string )
      string = Sanitizer.adjust_semicolon(string)
      string = Sanitizer.adjust_encoding(string)
      string = Sanitizer.adjust_quotation(string)
      string = Sanitizer.adjust_mime_type(string)
      string = Sanitizer.adjust_invalid_content_transfer_encoding(string)

      begin
        super(string)
      rescue Mail::Field::ParseError => e
        warn e.message
        @main_type = 'application'
        @sub_type = 'unknown'
        @parameters = ['name' => string]
      end
    end
  end
  class ContentTypeElement
    prepend ContentTypeElementFix
  end
end
