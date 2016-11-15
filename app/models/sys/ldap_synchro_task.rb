class Sys::LdapSynchroTask < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Auth::Manager

  attr_reader :fetch_results, :synchro_results

  has_one :target_tenant_root_group, -> { where(level_no: 1) },
    primary_key: :target_tenant_code, foreign_key: :tenant_code, class_name: 'Sys::Group'

  has_many :ldap_synchros, primary_key: :version, foreign_key: :version, dependent: :delete_all

  validates :version, uniqueness: true

  def ldap_synchro_groups
    ldap_synchros.where(entry_type: 'group')
  end

  def ldap_synchro_users
    ldap_synchros.where(entry_type: 'user')
  end

  def target_tenant_name
    if target_tenant_code.present?
      target_tenant_root_group.try(:name) || target_tenant_code
    else
      'すべて'
    end
  end

  def create_synchro
    @fetch_results = { group: 0, gerr: 0, user: 0, uerr: 0 }

    transaction do
      dcs = Core.ldap.dc.children || [Core.ldap.dc.root].compact
      dcs.each do |dc|
        next if target_tenant_code.present? && target_tenant_code != dc.tenant_code
        create_synchros(dc.tenant_code, dc)
      end
    end

    @fetch_results[:group] = ldap_synchro_groups.size
    @fetch_results[:user] = ldap_synchro_users.size

    self.fetch_log = self.class.make_fetch_log(@fetch_results)
    self.save
    self
  end

  def synchronize
    @synchro_results = { group: 0, gerr: 0, user: 0, uerr: 0, udel: 0, gdel: 0, uskip: 0, gskip: 0 }

    if target_tenant_code.present?
      synchronize_for_tenant(target_tenant_code)
    else
      synchronize_for_all
    end

    self.synchro_log = self.class.make_synchro_log(@synchro_results)
    self.save
    self
  end

  private

  def create_synchros(current_tenant_code, entry, parent = nil)
    group = Sys::LdapSynchro.new(
      parent_id:    parent.try!(:id).to_i,
      version:      version,
      tenant_code:  current_tenant_code,
      entry_type:   'group',
      code:         entry.code,
      name:         entry.name,
      name_en:      entry.name_en,
      email:        entry.email,
      group_s_name: entry.group_s_name,
      sort_no:      entry.sort_no
    )

    if group.save
      @fetch_results[:group] += 1
    else
      @fetch_results[:gerr] += 1
      return false
    end

    entry.users.each do |e|
      user = Sys::LdapSynchro.new(
        parent_id:         group.id,
        version:           version,
        tenant_code:       current_tenant_code,
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
        @fetch_results[:user] += 1
      else
        @fetch_results[:uerr] += 1
      end
    end

    entry.groups.each do |e|
      create_synchros(current_tenant_code, e, group)
    end
  end

  def synchronize_for_all
    tenant_codes = ldap_synchro_groups.where(parent_id: 0).pluck(:tenant_code)
    tenant_codes += Sys::Group.where(ldap: 1, parent_id: 0).pluck(:tenant_code)
    tenant_codes.uniq.sort.each do |tenant_code|
      synchronize_for_tenant(tenant_code)
    end
  end

  def synchronize_for_tenant(tenant_code)
    uids = Sys::User.in_tenant(tenant_code).pluck(:id)
    gids = Sys::Group.in_tenant(tenant_code).pluck(:id)

    transaction do
      Sys::User.where(id: uids).update_all(ldap_version: nil)
      Sys::Group.where(id: gids).update_all(ldap_version: nil)

      items = ldap_synchro_groups.where(tenant_code: tenant_code, parent_id: 0).order(:sort_no, :code)
      items.each { |group| do_synchro(group) }

      @synchro_results[:udel] += Sys::User.where(id: uids, ldap: 1, ldap_version: nil).destroy_all.size
      @synchro_results[:gdel] += Sys::Group.where(id: gids, ldap: 1, ldap_version: nil).destroy_all.size
    end
  end

  def do_synchro(group, parent = nil)
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
        @synchro_results[:group] += 1
      else
        @synchro_results[:gerr] += 1
        return false
      end
    else
      @synchro_results[:gskip] += 1
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
            @synchro_results[:user] += 1
          else
            @synchro_results[:uerr] += 1
          end
        else
          @synchro_results[:uskip] += 1
        end
      end
    end

    ## next
    group.children.each { |g| do_synchro(g, sg) }
  end

  class << self
    def run
      Core.ldap.bind_as_master

      task = Sys::LdapSynchroTask.new(version: Time.now.to_i)
      unless task.valid?
        task.fetch_log = 'ERROR: LDAP同期タスクの作成に失敗しました。'
        return task
      end

      task.create_synchro

      if task.fetch_results[:group] == 0 || task.fetch_results[:user] == 0 ||
         task.fetch_results[:gerr] != 0 || task.fetch_results[:uerr] != 0
        task.fetch_log = "ERROR: LDAP検索に失敗しました。 #{task.fetch_log}"
        task.save
        return task
      end

      task.synchronize
      task
    end

    def cleanup(max = Joruri.config.application['sys.ldap_synchro_max_count'].to_i)
      if max > 0
        self.order(id: :desc).offset(max).destroy_all.size
      else
        0
      end
    end

    def make_fetch_log(result)
      msgs = []
      msgs << "グループ 作成: #{result[:group]}, 失敗: #{result[:gerr]}"
      msgs << "ユーザー 作成: #{result[:user]}, 失敗: #{result[:uerr]}"
      msgs.join(', ')
    end

    def make_synchro_log(result)
      msgs = []
      msgs << "グループ 更新: #{result[:group]}, 削除: #{result[:gdel]}, 失敗: #{result[:gerr]}, 対象外: #{result[:gskip]}"
      msgs << "ユーザー 更新: #{result[:user]}, 削除: #{result[:udel]}, 失敗: #{result[:uerr]}, 対象外: #{result[:uskip]}"
      msgs.join(', ')
    end
  end
end
