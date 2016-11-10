class Sys::LdapSynchro < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Tree
  include Sys::Model::Auth::Manager

  validates :version, :entry_type, :code, :name, presence: true

  def children
    return @_children if @_children
    @_children = self.class.where(version: version, parent_id: id, entry_type: 'group').order(:sort_no, :code)
  end

  def users
    return @_users if @_users
    @_users = self.class.where(version: version, parent_id: id, entry_type: 'user').order(:sort_no, :code)
  end

  def group_count
    self.class.where(version: version, entry_type: 'group').count
  end

  def user_count
    self.class.where(version: version, entry_type: 'user').count
  end

  class << self
    def run
      Core.ldap.bind_as_master

      version = Time.now.to_i
      results = create_synchro(version)
      return results if results[:group] == 0 || results[:user] == 0

      synchronize(version)
    end

    def create_synchro(version = Time.now.to_i)
      opts = { version: version, group: 0, gerr: 0, user: 0, uerr: 0 }

      dcs = Core.ldap.dc.children || [Core.ldap.dc.root].compact
      dcs.each do |dc|
        opts[:tenant_code] = dc.tenant_code
        create_synchros(opts, dc)
      end
      opts
    end

    def synchronize(version)
      Sys::Group.update_all(ldap_version: nil)
      Sys::User.update_all(ldap_version: nil)

      opts = { version: version, group: 0, gerr: 0, user: 0, uerr: 0, udel: 0, gdel: 0 }

      items = Sys::LdapSynchro.where(version: version, parent_id: 0, entry_type: 'group').order(:sort_no, :code)
      items.each { |group| do_synchro(opts, group) }

      opts[:udel] = Sys::User.where(ldap: 1, ldap_version: nil).destroy_all.size
      opts[:gdel] = Sys::Group.where(ldap: 1, ldap_version: nil).destroy_all.size
      opts
    end

    private

    def create_synchros(opts, entry, parent = nil)
      group = Sys::LdapSynchro.new(
        parent_id:    parent.try!(:id).to_i,
        version:      opts[:version],
        tenant_code:  opts[:tenant_code],
        entry_type:   'group',
        code:         entry.code,
        name:         entry.name,
        name_en:      entry.name_en,
        email:        entry.email,
        group_s_name: entry.group_s_name,
        sort_no:      entry.sort_no
      )

      if group.save
        opts[:group] += 1
      else
        opts[:gerr] += 1
        return false
      end

      entry.users.each do |e|
        user = Sys::LdapSynchro.new(
          parent_id:         group.id,
          version:           opts[:version],
          tenant_code:       opts[:tenant_code],
          entry_type:        'user',
          code:              e.uid,
          name:              e.name,
          name_en:           e.name_en,
          email:             e.email,
          kana:              e.kana,
          sort_no:           e.sort_no,
          official_position: e.official_position,
          assigned_job:      e.assigned_job,
          group_s_name:      e.group_s_name
        )
        if user.save
          opts[:user] += 1
        else
          opts[:uerr] += 1
        end
      end

      entry.groups.each do |e|
        create_synchros(opts, e, group)
      end
    end

    def do_synchro(opts, group, parent = nil)
      ## group
      sg                = Sys::Group.where(tenant_code: group.tenant_code, code: group.code).first_or_initialize
      sg.code           = group.code
      sg.parent_id      = parent.try!(:id).to_i
      sg.state        ||= 'enabled'
      sg.web_state    ||= 'public'
      sg.name           = group.name
      sg.name_en        = group.name_en if group.name_en.present?
      sg.email          = group.email if group.email.present?
      sg.group_s_name   = group.group_s_name
      sg.level_no       = parent.try!(:level_no).to_i + 1
      sg.sort_no        = group.sort_no
      sg.ldap         ||= 1
      sg.ldap_version   = group.version

      if sg.ldap == 1
        if sg.save(validate: false)
          opts[:group] += 1
        else
          opts[:gerr] += 1
          return false
        end
      end

      ## users
      if group.users.size > 0
        group.users.each do |user|
          su                   = Sys::User.where(account: user.code).first_or_initialize
          su.account           = user.code
          su.state           ||= 'enabled'
          su.auth_no         ||= 2
          su.name              = user.name
          su.name_en           = user.name_en
          su.email             = user.email
          su.kana              = user.kana
          su.sort_no           = user.sort_no
          su.official_position = user.official_position
          su.assigned_job      = user.assigned_job
          su.group_s_name      = user.group_s_name
          su.ldap            ||= 1
          su.ldap_version      = user.version
          su.in_group_id       = sg.id

          if su.ldap == 1
            if su.save
              opts[:user] += 1
            else
              opts[:uerr] += 1
            end
          end
        end
      end

      ## next
      group.children.each { |g| do_synchro(opts, g, sg) }
    end
  end
end
