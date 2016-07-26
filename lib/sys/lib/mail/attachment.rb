class Sys::Lib::Mail::Attachment
  attr_reader :seqno
  attr_reader :content_type
  attr_reader :name
  attr_reader :body
  attr_reader :size
  attr_reader :transfer_encoding

  def initialize(attributes = {})
    attributes.each {|name, value| eval("@#{name} = value")}
  end

  def image?
    !(@content_type =~ /^image/i).nil?
  end

  def disposition
    image? ? 'inline' : 'attachment'
  end

  def thumbnail(width: 64, height: 64, format: 'jpeg', quality: 50, method: :thumbnail)
    return nil unless image?

    image = Magick::Image.from_blob(@body).shift
    thumb_w, thumb_h = self.class.reduce_size(image.columns, image.rows, width, height)
    if image.columns > thumb_w || image.rows > thumb_h
      image.format = format.to_s
      case method
      when :sample
        image.sample!(thumb_w, thumb_h)
      when :thumbnail
        image.thumbnail!(thumb_w, thumb_h)
      else
        image.resize!(thumb_w, thumb_h)
      end
      image.to_blob { self.quality = quality }
    else
      image.to_blob
    end
  rescue => e
    error_log(e)
    nil
  end

  def css_class
    if ext = File::extname(@name.to_s).downcase[1..5]
      ext = ext.gsub(/[^0-9a-z]/, '').gsub(/\b\w/) { |word| word.upcase }
      "iconFile icon#{ext}"
    else
      'iconFile'
    end
  end

  def eng_unit
    @eng_unit ||= ApplicationController.helpers.number_to_human_size(@size, precision: 0, locale: :en)
  end

  class << self
    def reduce_size(src_width, src_height, dst_width, dst_height)
      src_w = src_width.to_f
      src_h = src_height.to_f
      dst_w = dst_width.to_f
      dst_h = dst_height.to_f
      src_r = src_w / src_h
      dst_r = dst_w / dst_h
      if dst_r > src_r
        dst_w = dst_h * src_r
      else
        dst_h = dst_w / src_r
      end
      return dst_w.ceil, dst_h.ceil
    end
  end
end
