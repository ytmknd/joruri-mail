class Sys::Lib::Ldap::Dc < Sys::Lib::Ldap::Entry
  include Sys::Lib::Ldap::Base::Group

  ## Initializer.
  def initialize(connection, attributes = {})
    super
    @primary = "dc"
    @filter  = "(objectClass=dcObject)"
  end

  def o
    get(:o)
  end

  def dc
    get(:dc)
  end

  def tenant_code
    get(:seeAlso)
  end

  def code
    dc
  end

  def name
    o
  end

  def root
    find_by_dn(@connection.config[:base])
  end
end
