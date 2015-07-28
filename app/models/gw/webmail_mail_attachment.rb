# encoding: utf-8
require 'shared-mime-info'
class Gw::WebmailMailAttachment < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::File
  include Sys::Model::Auth::Free
  
  set_table_name 'sys_files'
  
  def maxsize
    Joruri.config.application['webmail.attachment_file_max_size'] * (1024**2)
  end
  
  def upload_path
    id_dir  = format('%08d', id).gsub(/(.*)(..)(..)(..)$/, '\1/\2/\3/\4/\1\2\3\4')
    id_file = format('%07d', id) + '.dat'
    "#{Rails.root}/upload/sys/files/#{id_dir}/#{id_file}"
  end
  
  def read
    ::File.new(upload_path).read
  end
  
  def save_file(file)
    raise "ファイルがアップロードされていません。" if file.blank?
    
    self.mime_type = file.content_type
    self.size      = file.size
    raise "容量制限を超えています。＜#{maxsize/(1024**2)}MB＞" if size > maxsize
    
    total_size = self.size + self.class.find(:all, :conditions => {:tmp_id => tmp_id}).map{|c| c.size.to_i}.inject(&:+).to_i
    raise "容量制限を超えています。＜#{maxsize/(1024**2)}MB＞" if total_size > maxsize
    
    self.name    ||= file.original_filename
    self.title   ||= name
    raise "ファイル名を入力してください。" if name.blank?
    
    self.mime_type = MIME.check_globs(self.name).type rescue nil
    if self.mime_type.blank?
      self.mime_type = MIME.check_magics(file.path).type rescue "application/octet-stream"
    end
    
    @filedata      = file.read
    if self.name =~ /\.(gif|jpg|jpeg|png)$/i && image_size = validate_image(@filedata)
      self.image_is     = 1
      self.image_width  = image_size[0]
      self.image_height = image_size[1]
    end
    
    begin
      save(:validate => false)
      Util::File.put(upload_path, :data => @filedata, :mkdir => true, :use_lock => false)
    rescue => e
      destroy
      raise e
    end
    return true
  rescue => e
    errors.add :base, e.to_s
    return false
  end
  
  def validate_image(filedata)
    begin
      require 'RMagick'
      image = Magick::Image.from_blob(filedata).shift
      if image.format =~ /(GIF|JPEG|PNG)/
        return [image.columns, image.rows]
      end
    rescue Exception
      return false
    end
  end
end
