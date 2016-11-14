require 'ldap'
class Sys::Lib::Ldap
  attr_accessor :config

  ## Initializer.
  def initialize(params = {})
    self.config = Util::Config.load(:ldap).symbolize_keys
    self.config = config.merge!(params)

    config[:bind_dn] ||= "uid=[uid],[ous],[base]"
    config[:charset] ||= "utf-8"
  end

  def connection
    if config[:host].present? && config[:port].present?
      @connection ||= self.class.connect(config)
    else
      @connection = nil
    end
  end

  ## Connect.
  def self.connect(config)
    begin
      Timeout.timeout(2) do
        conn = LDAP::Conn.new(config[:host], config[:port])
        conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
        return conn
      end
    rescue Timeout::Error => e
      raise "LDAP: 接続に失敗 (#{e})"
    rescue Exception => e
      raise "LDAP: エラー (#{e})"
    end
  end

  ## Bind.
  def bind(dn, pass)
    if(RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|bccwin/)
      dn = NKF.nkf('-s -W', dn)
    end
    return connection.bind(dn, pass)
  rescue LDAP::ResultError
    return nil
  end

  def bind_as_master
    bind(config[:username], config[:password]) if config[:username].present? && config[:password].present?
  end

  ## Group.
  def group
    Sys::Lib::Ldap::Group.new(self)
  end
  
  ## User
  def user
    Sys::Lib::Ldap::User.new(self)
  end
  
  ## Search.
  def search(filter, options = {})
    filter = "(#{filter.join(')(')})" if filter.class == Array
    filter = "(&#{filter})"
    
    cname = options[:class] || Sys::Lib::Ldap::Entry
    scope = options[:scope] || LDAP::LDAP_SCOPE_SUBTREE || LDAP::LDAP_SCOPE_ONELEVEL
    base  = options[:base]  || config[:base]
    entries = []
    connection.search2(base, scope, filter) do |entry|
      entry.each{|k,vs| entry[k] = vs.map{|v| NKF::nkf('-w', v.to_s)}} if config[:charset] != 'utf-8'
      entries << cname.new(self, entry)
    end
    
    return entries
  rescue
    return []
  end
end