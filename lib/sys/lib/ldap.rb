require 'net/ldap'

class Sys::Lib::Ldap
  SCOPE_SUBTREE = Net::LDAP::SearchScope_WholeSubtree
  SCOPE_ONELEVEL = Net::LDAP::SearchScope_SingleLevel

  class Connection
    attr_reader :config

    def initialize(config)
      @config = config
      @bound = false
      reset_client
      ldap.open { true }
    end

    def bind(dn, pass)
      ldap.auth(dn, pass)
      @bound = ldap.bind
    rescue Net::LDAP::Error
      @bound = false
    end

    def bound?
      @bound
    end

    def unbind
      @bound = false
      reset_client
      true
    end

    def search(base:, scope:, filter:)
      ldap.search(base: base, scope: scope, filter: filter) do |entry|
        yield entry
      end
    end

    private

    attr_reader :ldap

    def reset_client
      @ldap = Net::LDAP.new(host: config[:host], port: config[:port].to_i)
    end
  end

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
        return Connection.new(config)
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
  rescue Net::LDAP::Error
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
    filter = filter.to_s.empty? ? "(objectClass=*)" : "(&#{filter})"
    
    cname = options[:class] || Sys::Lib::Ldap::Entry
    scope = options[:scope] || SCOPE_SUBTREE
    base  = options[:base]  || config[:base]
    entries = []
    connection.search(base: base, scope: scope, filter: Net::LDAP::Filter.construct(filter)) do |entry|
      attributes = { 'dn' => [entry.dn] }
      entry.each do |key, values|
        attributes[key.to_s] = Array(values).map do |value|
          value = value.to_s
          config[:charset] == 'utf-8' ? value : NKF.nkf('-w', value)
        end
      end
      entries << cname.new(self, attributes)
    end
    
    return entries
  rescue
    return []
  end
end
