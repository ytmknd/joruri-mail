class Core
  ## Core attributes.
  cattr_reader   :now
  cattr_reader   :config
  cattr_accessor :title
  cattr_reader   :map_key
  cattr_reader   :script_uri
  cattr_reader   :request_uri
  cattr_reader   :internal_uri
  cattr_accessor :ldap
  cattr_accessor :imap
  cattr_accessor :user
  cattr_accessor :user_group
  cattr_accessor :current_user
  cattr_accessor :switch_users
  cattr_accessor :dispatched

  ## Initializes.
  def self.initialize(env = {})
    @@now          = Time.now.to_s(:db)
    @@config       = Util::Config.load(:core)
    @@title        = @@config['title'] || 'Joruri'
    @@map_key      = @@config['map_key']
    @@script_uri   = env['SCRIPT_URI'] || "http://#{env['HTTP_HOST']}#{env['PATH_INFO']}"
    @@request_uri  = nil
    @@internal_uri = nil
    @@ldap         = nil
    @@imap         = nil
    @@user         = nil
    @@user_group   = nil
    @@current_user = nil
    @@switch_users = nil
    @@dispatched   = nil
    
    #require 'page'
###    Page.initialize
  end

  ## Now.
  def self.now
    return @@now if @@now
    return @@now = Time.now.to_s(:db)
  end

  ## Absolute path.
  def self.uri
    @@config['uri'].sub(/^[a-z]+:\/\/[^\/]+\//, '/')
  end

  ## Full URI.
  def self.full_uri
    @@config['uri']
  end

  ## Proxy.
  def self.proxy
    @@config['proxy']
  end

  ## LDAP.
  def self.ldap
    return @@ldap if @@ldap
    @@ldap = Sys::Lib::Ldap.new
  end

  ## IMAP.
  def self.imap
    return @@imap if @@imap
    @@imap = Sys::Lib::Net::Imap.connect
  end

  ## Controller was dispatched?
  def self.dispatched?
    @@dispatched
  end

  ## Controller was dispatched.
  def self.dispatched
    @@dispatched = true
  end

  ## Recognizes the path for dispatch.
  def self.recognize_path(path)
    @@request_uri = @@internal_uri = path
  end

  def self.terminate
    if @@ldap
      @@ldap.connection.unbind rescue nil
      @@ldap = nil
    end
    if @@imap
      @@imap.logout rescue nil
      @@imap.disconnect rescue nil
      @@imap = nil
    end
  end
end
