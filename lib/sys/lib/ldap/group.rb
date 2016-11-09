class Sys::Lib::Ldap::Group < Sys::Lib::Ldap::Entry
  ## Initializer.
  def initialize(connection, attributes = {})
    super
    @primary = "ou"
    @filter  = "(objectClass=top)(objectClass=organizationalUnit)(!(ou=Groups))(!(ou=People))(!(ou=Special*))"
  end

  ## Attribute: ou
  def ou
    get(:ou)
  end

  ## Attribute: code
  def code
    return nil unless ou
    return ou unless ou =~ /^[0-9a-zA-Z]+[^0-9a-zA-Z]/
    return ou.gsub(/^([0-9a-zA-Z]+)(.*)/, '\1')
  end

  ## Attribute: name
  def name
    return nil unless ou
    return ou unless ou =~ /^[0-9a-zA-Z]+[^0-9a-zA-Z]/
    return ou.gsub(/^([0-9a-zA-Z]+)(.*)/, '\2')
  end

  ## Attribute: name(english)
  def name_en
    group_user ? group_user.get('sn;lang-en') : nil
  end

  ## Attribute: email
  def email
    group_user ? group_user.get(:mail) : nil
  end

  ## Attribute: group_s_name
  def group_s_name
    group_user ? group_user.get(:roomNumber) : nil
  end

  def tel
    get(:telephoneNumber)
  end

  def sort_no
    get(:description)
  end

  ## Return the group user for group's attributes.
  def group_user
    @connection.user.search("(cn=#{name})",
      base: dn,
      scope: LDAP::LDAP_SCOPE_ONELEVEL
    ).first
  end
end
