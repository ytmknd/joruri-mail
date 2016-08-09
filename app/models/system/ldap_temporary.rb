class System::LdapTemporary < System::Database
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Auth::Manager
  
  def synchro_target?
    #return ou =~ /^[0-9]/ ? true : nil
    #return get('givenName') ? true : nil
    return true
  end

  def ldap_children
    self.class.where(version: version, parent_id: id, data_type: 'group').order(:code)
  end

  def ldap_users
    self.class.where(version: version, parent_id: id, data_type: 'user').order(:code)
  end
end
