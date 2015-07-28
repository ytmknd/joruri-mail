class Sys::Publisher < ActiveRecord::Base
  include Sys::Model::Base
  
  #validates_presence_of :unid
  
  before_validation :modify_path
  before_destroy :close
  
  def modify_path
    self.published_path = published_path.gsub(/^#{Rails.root.to_s}/, '.')
  end
  
  def close
    path = published_path
    path = "#{Rails.root}/#{path}" unless path.slice(0, 1) == '/'
    FileUtils.rm(path) if FileTest.exist?(path)

    ## sound file to talk
#    if path =~ /\.html$/
#      sound = path + '.mp3'
#      File.delete(sound) if FileTest.exist?(sound)
#    end

    begin
      Dir::rmdir(File::dirname(path))
    rescue
      return true
    end
    return true
  end
end
