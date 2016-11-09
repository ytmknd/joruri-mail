class Sys::Lib::Ldap::Entry
  def initialize(connection, attributes = {})
    attributes.each do |key, val|
      val.each_with_index do |v, k|
        attributes[key][k] = v.force_encoding("utf-8")
      end
    end

    @connection = connection
    @attributes = attributes
    @primary     = nil
    @filter      = nil
  end

  def attributes
    @attributes
  end

  def get(name, position = 0)
    name = name.to_s
    if position == :all
      @attributes[name] ? @attributes[name] : []
    elsif @attributes[name]
      @attributes[name][position]
    else
      nil
    end
  end

  def object_classes
    get(:objectClass, :all)
  end

  def dc_object?
    object_classes.include?('dcObject')
  end

  def group_object?
    object_classes.include?('organizationalUnit')
  end

  def user_object?
    object_classes.include?('organizationalPerson')
  end

  def display_name
    get(:cn) || get(:ou) || get(:o) || get(:dn)
  end

  def dn
    get(:dn)
  end

  def search(filter, options = {})
    filter = "(#{filter.join(')(')})" if filter.class == Array
    filter = "#{filter}(&#{@filter})"
    options[:class] ||= self.class
    return @connection.search(filter, options)
  end

  def find(id, options = {})
    filter = "(#{@primary}=#{id})(&#{@filter})"
    options[:class] ||= self.class
    return @connection.search(filter, options)[0]
  end

  def find_by_dn(dn)
    dns = dn.split(',')
    search([dns[0]],
      base: dn,
      scope: LDAP::LDAP_SCOPE_BASE
    ).first
  end

  ## Returns the parent group.
  def parent
    dns = dn.split(',')
    return nil if dns.size == 1

    search([dns[1]],
      base: dns[1..-1].join(','),
      scope: LDAP::LDAP_SCOPE_BASE
    ).first
  end

  ## Returns the parent groups without self.
  def parents(items = [])
    items.unshift(self)
    parent.parents(items) if parent
    items
  end

  ## Returns the children.
  def children
    search(nil,
      base: dn,
      scope: LDAP::LDAP_SCOPE_ONELEVEL
    )
  end

  ## Returns the domain components.
  def dcs
    @connection.dc.search(nil,
      base: dn,
      scope: LDAP::LDAP_SCOPE_ONELEVEL
    )
  end

  ## Returns the groups.
  def groups
    @connection.group.search(nil,
      base: dn,
      scope: LDAP::LDAP_SCOPE_ONELEVEL
    )
  end

  ## Returns the users.
  def users
    @connection.user.search(nil,
      base: dn,
      scope: LDAP::LDAP_SCOPE_ONELEVEL,
    )
  end
end
