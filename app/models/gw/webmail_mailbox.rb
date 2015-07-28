# encoding: utf-8
require 'net/ssh'
require "net/imap"
require "rexml/document"

class Gw::WebmailMailbox < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free
  
#  attr_accessor :id, :path, :name, :full_name
  attr_accessor :path, :path_was, :name_was
  
  validates_presence_of :title
  validate :validate_title
  
  def self.imap
    Core.imap
  end
  
  def self.imap_mailboxes
    boxes = {:INBOX => [], :Drafts => [], :Sent => [], :Archives => [], :Trash => [], :Star => [], :Etc => []}
    list  = imap.list('', '*')
    list  = list.sort{|a, b| name_to_title(a.name).downcase <=> name_to_title(b.name).downcase}
    list.each do |box|
      type = :Etc
      [:INBOX, :Drafts, :Sent, :Archives, :Trash, :Star].each do |name|
        if box.name =~ /^#{name.to_s}(\.|$)/
          type = name
          break
        end
      end
      boxes[type] <<  box
    end
    boxes[:INBOX] + boxes[:Star] + boxes[:Drafts] + boxes[:Sent] + boxes[:Archives] + boxes[:Etc] + boxes[:Trash]
  end
  
  def self.load_mailbox(mailbox)
    if box = find(:first, :conditions => {:user_id => Core.current_user.id, :name => mailbox})
      imap.select(mailbox)
      imap.expunge
      unseen = imap.status(mailbox, ['UNSEEN'])['UNSEEN']
      if box.unseen != unseen
        box.unseen = unseen
        box.save(:validate => false)
      end
      return box
    end
    load_mailboxes(:all)
    self.new({
      :user_id  => Core.current_user.id,
      :name     => mailbox,
      :title    => name_to_title(mailbox).gsub(/.*\./, '')
    })
  end
  
  def self.load_mailboxes(reload = nil)
    if reload.class == String
      if box = find(:first, :conditions => {:user_id => Core.current_user.id, :name => reload})
        status = imap.status(reload, ['MESSAGES', 'UNSEEN', 'RECENT'])
        box.messages = status['MESSAGES']
        box.unseen   = status['UNSEEN']
        box.recent   = status['RECENT']
        reload = nil if box.save
      else
        reload = :all
      end
    elsif reload.class == Array
      if reload.index(:all)
        reload = :all
      else
        reload.each do |boxname|
          if box = find(:first, :conditions => {:user_id => Core.current_user.id, :name => boxname})
            status = imap.status(boxname, ['MESSAGES', 'UNSEEN', 'RECENT'])
            box.messages = status['MESSAGES']
            box.unseen   = status['UNSEEN']
            box.recent   = status['RECENT']
            box.save
          end
        end
        reload = nil
      end
    end
    
    Util::Database.lock_by_name(Core.current_user.account) do
      boxes = find(:all, :conditions => {:user_id => Core.current_user.id}, :order => :sort_no)
      return boxes if reload == nil && boxes.size > 0
      
      need = ['Drafts', 'Sent', 'Archives', 'Trash', 'Star']
      (imap_boxes = imap_mailboxes).each do |box|
        need.delete('Drafts')   if box.name == 'Drafts'
        need.delete('Sent')     if box.name == 'Sent'
        need.delete('Trash')    if box.name == 'Trash'
        need.delete('Archives') if box.name == 'Archives'
        need.delete('Star')     if box.name == 'Star'
      end
      if need.size > 0
        need.each {|name| imap.create(name) }
        imap_boxes = imap_mailboxes
      end
      
      imap_box_names = imap_boxes.collect{|b| b.name}
      boxes.each {|box| box.destroy unless imap_box_names.index(box.name) }
      
      imap_boxes.each_with_index do |box, idx|
        item = nil
        boxes.each do |b|
          if b.name == box.name
            item = b
            break
          end
        end
        status = imap.status(box.name, ['MESSAGES', 'UNSEEN', 'RECENT'])
        item ||= self.new
        item.attributes = {
          :user_id  => Core.current_user.id,
          :sort_no  => idx + 1,
          :name     => box.name,
          :title    => name_to_title(box.name).gsub(/.*\./, ''),
          :messages => status['MESSAGES'],
          :unseen   => status['UNSEEN'],
          :recent   => status['RECENT']
        }
        item.save(:validate => false) if item.changed?
      end
    end
    
    return find(:all, :conditions => {:user_id => Core.current_user.id}, :order => :sort_no)
  end
  
  def self.load_starred_mails(mailbox_uids = nil)
    return if mailbox_uids == nil
    
    imap.create('Star') unless imap.list('', 'Star')
    
    imap.select('Star') rescue return
    unstarred_uids = imap.uid_search(['UNDELETED', 'UNFLAGGED'])
    num = imap.uid_store(unstarred_uids, '+FLAGS', [:Deleted]).size rescue 0
    imap.expunge if num > 0
    
    Gw::WebmailMailNode.delete_nodes('Star', unstarred_uids) if num > 0
    
    mailbox_uids.each do |mailbox, uids|
      next if mailbox =~ /^(Star)$/
      
      current_starred_uids = Gw::WebmailMailNode.find_ref_nodes(mailbox).map{|x| x.ref_uid}
      
      imap.select(mailbox) rescue next
      if uids.empty? || uids.include?('all') ||  uids.include?(:all)
        new_starred_uids = imap.uid_search(['UNDELETED', 'FLAGGED'])
      else
        new_starred_uids = imap.uid_search(['UID', uids, 'UNDELETED', 'FLAGGED'])
      end
      new_starred_uids = new_starred_uids.select{|x| !current_starred_uids.include?(x) }
      next if new_starred_uids.blank?
      
      imap.select('Star') rescue next
      next_uid = imap.status('Star', ['UIDNEXT'])['UIDNEXT']
      
      imap.select(mailbox) rescue next
      res = imap.uid_copy(new_starred_uids, 'Star') rescue next
      next if res.name != 'OK'

      # create cache
      items = Gw::WebmailMail.fetch((next_uid..next_uid+new_starred_uids.size).to_a, 'Star', :use_cache => false)
      items.each_with_index do |item, i|
        if item.node
          item.node.ref_mailbox = mailbox
          item.node.ref_uid = new_starred_uids[i]
          item.node.save
        end
      end
    end
  end
  
  def self.name_to_title(name)
    name = Net::IMAP.decode_utf7(name)
    name = name.gsub(/^INBOX(\.|$)/, '受信トレイ\1')
    name = name.gsub(/^Drafts(\.|$)/, '下書き\1')
    name = name.gsub(/^Sent(\.|$)/, '送信トレイ\1')
    name = name.gsub(/^Trash(\.|$)/, 'ごみ箱\1')
    name = name.gsub(/^Archives(\.|$)/, 'アーカイブ\1')
    name = name.gsub(/^Star(\.|$)/, 'スター付き\1')
    name
  end
  
  def self.load_quota(reload = nil)
    quota = nil
    cond  = {:user_id => Core.current_user.id, :name => 'quota_info'}
    st    = Gw::WebmailSetting.find(:first, :conditions => cond)
    
    #if reload != :force
    #  reload = nil if reload && rand(3) != 0
    #end
    
    if !reload && !st.nil?
      begin
        #xml = REXML::Document.new(st.value)
        #xml.root.elements.each {|e| quota[e.name.intern] = e.text }
        quota = Hash.from_xml(st.value)
        if quota.values.length > 0
          quota = quota.values[0].symbolize_keys
          if quota[:mailboxes] && quota[:mailboxes].values.length > 0
            quota[:mailboxes] = quota[:mailboxes].values[0].each {|x| x.symbolize_keys!}
          end
        end
      rescue => e
        return nil
      end
      return quota
    end
    
    begin
      quota = get_quota_info
    rescue => e
      error_log("#{e}: #{res}")
      quota = nil
    end
    
    if quota
      st ||= Gw::WebmailSetting.new(cond)
      st.value = quota.to_xml(:dasherize => false, :skip_types => true, :root => 'item')
      st.save(:validate => false)
    end
    
    return quota
  end
  
  def self.get_quota_info
    return nil unless imap.capability.include?("QUOTA")
    
    res = imap.getquotaroot('INBOX')[1] # sample: "" (STORAGE 258334 307200 MESSAGES 3145 10000)
    if m = res.match(/\(STORAGE ([0-9]+) ([0-9]+).*/)
      quota_bytes      = m[1].to_i*1024
      max_quota_bytes  = m[2].to_i*1024
      warn_quota_bytes = max_quota_bytes * Joruri.config.application['webmail.mailbox_quota_alert_rate'].to_f
      #messages         = m[3].to_i
      #max_messages     = m[4].to_i
      
      quota = {}
      quota[:total_bytes] = max_quota_bytes
      quota[:total]       = Util::Unit.eng_unit(max_quota_bytes).gsub(/\.[0-9]+/, '')
      quota[:used_bytes]  = quota_bytes
      quota[:used]        = Util::Unit.eng_unit(quota_bytes).gsub(/\.[0-9]+/, '')
      quota[:usage_rate]  = sprintf('%.1f', quota_bytes.to_f / max_quota_bytes.to_f * 100).to_f
      if quota_bytes > warn_quota_bytes
        quota[:usable] = Util::Unit.eng_unit(max_quota_bytes - quota_bytes).gsub(/\.[0-9]+/, '') 
      end
    end
    
    return quota
  end
  
  def self.exist?(mailbox)
    find(:first, :conditions => {:user_id => Core.current_user.id, :name => mailbox.to_s}) ? true : false
  end
  
  def readable
    self.and :user_id, Core.current_user.id
    self
  end
  
  def creatable?
    return true if Core.current_user.has_auth?(:manager)
    user_id == Core.current_user.id
  end
  
  def editable?
    return true if Core.current_user.has_auth?(:manager)
    user_id == Core.current_user.id
  end
  
  def deletable?
    return true if Core.current_user.has_auth?(:manager)
    user_id == Core.current_user.id
  end
  
  def draft_box?(target = :self)
    case target
    when :all      ; name =~ /^Drafts(\.|$)/
    when :children ; name =~ /^Drafts\./
    else           ; name == "Drafts"
    end
  end
  
  def sent_box?(target = :self)
    case target
    when :all      ; name =~ /^Sent(\.|$)/
    when :children ; name =~ /^Sent\./
    else           ; name == "Sent"
    end
  end
  
  def trash_box?(target = :self)
    case target
    when :all      ; name =~ /^Trash(\.|$)/
    when :children ; name =~ /^Trash\./
    else           ; name == "Trash"
    end
  end
  
  def star_box?(target = :self)
    case target
    when :all      ; name =~ /^Star(\.|$)/
    when :children ; name =~ /^Star\./
    else           ; name == "Star"
    end
  end
  
  def parents_count
    name.gsub(/[^\.]/, '').length
  end
  
  def children
    cond = Condition.new
    cond.and :user_id, Core.current_user.id
    cond.and :name, '!=', "#{name}"
    cond.and :name, 'like', "#{name}.%"
    items = find(:all, :conditions => cond.where, :order => :sort_no)
    items.delete_if {|x| x.name =~ /#{name}\.[^\.]+\./}
  end
  
  def path
    return @path if @path
    return "" if name !~ /\./
    name.gsub(/(.*\.).*/, '\\1')
  end
  
  def slashed_title(char = "　 ")
    self.class.name_to_title(name).gsub('.', '/')
  end
  
  def indented_title(char = "　 ")
    "#{char * parents_count}#{title}"
  end
  
  def validate_title
    if title =~ /[\.\/\#\\]/
      errors.add :title, "に半角記号（ . / # \\ ）は使用できません。"
    end
  end
end