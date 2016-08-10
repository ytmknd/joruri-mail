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

  def self.create_synchro(version = Time.now.to_i)
    @version = version
    @results = { group: 0, gerr: 0, user: 0, uerr: 0 }

    self.create_synchros

    @results
  end
  
  def self.synchronize(version)
    @version = version
    @results = { group: 0, gerr: 0, user: 0, uerr: 0, udel: 0, gdel: 0, error: '' }

    items = Sys::LdapSynchro.where(version: @version, parent_id: 0, entry_type: 'group').order(:sort_no, :code)

    unless parent = Sys::Group.find_by(parent_id: 0)
      raise "グループのRootが見つかりません。"
    end

    Sys::Group.update_all(ldap_version: nil)
    Sys::User.update_all(ldap_version: nil)

    items.each { |group| do_synchro(group, parent) }

    @results[:udel] = Sys::User.where(ldap: 1, ldap_version: nil).destroy_all.size
    @results[:gdel] = Sys::Group.where(parent_id: 0, ldap: 1, ldap_version: nil).destroy_all.size

    @results
  end

  private

  def self.create_synchros(entry = nil, group_id = nil)
    if entry.nil?
      Core.ldap.group.children.each do |e|
        create_synchros(e, 0)
      end
      return true
    end

    group = Sys::LdapSynchro.new(
      parent_id:    group_id,
      version:      @version,
      entry_type:   'group',
      code:         entry.code,
      name:         entry.name,
      name_en:      entry.name_en,
      email:        entry.email,
      group_s_name: entry.group_s_name,
    )
    if group.save
      @results[:group] += 1
    else
      @results[:gerr] += 1
      return false
    end

    entry.users.each do |e|
      user = Sys::LdapSynchro.new(
        parent_id:         group.id,
        version:           @version,
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
        @results[:user] += 1
      else
        @results[:uerr] += 1
      end
    end

    entry.children.each do |e|
      create_synchros(e, group.id)
    end
  end
  
  def self.do_synchro(group, parent = nil)
    ## group
    sg                = Sys::Group.where(code: group.code).first_or_initialize
    sg.code           = group.code
    sg.parent_id      = parent.id
    sg.state        ||= 'enabled'
    sg.web_state    ||= 'public'
    sg.name           = group.name
    sg.name_en        = group.name_en if group.name_en.present?
    sg.email          = group.email if group.email.present?
    sg.group_s_name   = group.group_s_name
    sg.level_no       = parent.level_no + 1
    #sg.sort_no        = group.sort_no
    sg.ldap         ||= 1
    sg.ldap_version   = group.version

    if sg.ldap == 1
      if sg.save(validate: false)
        @results[:group] += 1
      else
        @results[:gerr] += 1
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
            @results[:user] += 1
          else
            @results[:uerr] += 1
          end
        end
      end
    end

    ## next
    if group.children.size > 0
      group.children.each { |g| do_synchro(g, sg) }
    end
  end
end
