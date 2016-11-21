class Util::File
  class << self
    def put(path, options ={})
      if options[:mkdir] == true
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless FileTest.exist?(dir)
      end
      if options[:data]
        begin
          f = File.open(path, "w")
          begin
            f.flock(File::LOCK_EX) if options[:use_lock] != false
            f.write(options[:data] ? options[:data].force_encoding('utf-8') : '')
            f.flock(File::LOCK_UN) if options[:use_lock] != false
          ensure
            f.close
          end
        end
      elsif options[:src]
        return false unless FileTest.exist?(options[:src])
        FileUtils.cp options[:src], path
      end
      return true
    end

    def filesystemize(name, length: nil, byte_size: nil, keep_ext: nil)
      sysname = name.gsub(/[\/\<\>\|:;"\?\*\\\r\n]/, '_')
      if length && length < sysname.length
        truncate_length(sysname, length: length, keep_ext: keep_ext)
      elsif byte_size && byte_size < sysname.bytesize
        truncate_byte_size(sysname, byte_size: byte_size, keep_ext: keep_ext)
      else
        sysname
      end
    end

    def truncate_length(name, length: 100, keep_ext: false)
      if keep_ext
        ext = File.extname(name)
        File.basename(name, '.*').match(/^.{1,#{length - ext.length}}/).to_s + File.extname(name)
      else
        name.match(/^.{#{length}}/).to_s
      end
    end

    def truncate_byte_size(name, byte_size: 255, keep_ext: false)
      basename = File.basename(name)
      ext = keep_ext ? File.extname(name) : ''
      str = ''
      name.chars.each do |c|
        break if byte_size < str.bytesize + c.bytesize + ext.bytesize
        str << c
      end
      str + ext
    end

    def unique_filenames(names)
      uniques = []
      names.each do |name|
        if uniques.include?(name)
          for n in 1..255
            seqname = "#{File.basename(name, ".*")}_#{n}#{File.extname(name)}"
            seqname = seqname.encode(name.encoding) if name.encoding != seqname.encoding
            unless uniques.include?(seqname)
              name = seqname
              break
            end
          end
        end
        uniques << name
      end
      uniques
    end
  end
end
