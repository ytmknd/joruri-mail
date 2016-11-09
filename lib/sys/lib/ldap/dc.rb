class Sys::Lib::Ldap::Dc < Sys::Lib::Ldap::Entry
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

  def code
    get(:seeAlso)
  end
end
