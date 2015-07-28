# encoding: utf-8
class Gw::WebmailAddress < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  has_many :groupings, :foreign_key => :address_id, :class_name => 'Gw::WebmailAddressGrouping',
    :dependent => :destroy
  has_many :groups, :through => :groupings, :order => 'name, id'
  #belongs_to :group, :foreign_key => :group_id, :class_name => 'Gw::WebmailAddressGroup'
  
  attr_accessor :easy_entry, :escaped, :in_groups
  
  validates_presence_of :user_id, :name, :email
  validate :validate_attributes

  after_save :save_groups
  
  #CONSTANTS
  NO_GROUP = 'no_group'
  
  def validate_attributes
    if easy_entry # from Ajax
      if !email.blank? && !name.blank?
        if self.class.find(:first, :conditions => {:user_id => Core.user.id, :email => email})
          errors.add :base, "既に登録されています。"
        else
          self.name  = CGI.unescapeHTML(name.to_s) if escaped
          self.name  = name.gsub(/^"(.*)"$/, '\\1')
          self.email = email
        end
      end
    end
    
    self.name = name.gsub(/["<>]/, '') if !name.blank?
    
    to_kana = lambda {|str| str.to_s.tr("ぁ-ん", "ァ-ン") }
    self.kana = to_kana.call(kana)
    self.company_kana = to_kana.call(company_kana)
  end
  
  def self.user_addresses
    self.find(:all, :conditions => {:user_id => Core.user.id})  
  end
  
  def readable
    self.and :user_id, Core.user.id
    self
  end
  
  def editable?
    return true if Core.user.has_auth?(:manager)
    user_id == Core.user.id
  end
  
  def deletable?
    return true if Core.user.has_auth?(:manager)
    user_id == Core.user.id
  end
  
  def search(params)
    
    like_param = lambda do |s|
      s.gsub(/[\\%_]/) {|r| "\\#{r}"}
    end
    
    params.each do |k, vs|
      next if vs.blank?
      
      vs.split(/[ 　]+/).each do |v|
        next if v == ''
        case k
        when 's_group_id'
          if v == NO_GROUP
            self.and :group_id, 'IS', nil
          else
            self.and :group_id, v
          end  
        when 's_name'
          self.and :name, 'LIKE', "%#{like_param.call(v)}%"
        when 's_email'
          self.and :email, 'LIKE', "%#{like_param.call(v)}%"
        when 's_name_or_kana'
          kana_v = v.to_s.tr("ぁ-ん", "ァ-ン")
          cond = Condition.new
          cond.or :name, 'LIKE', "%#{like_param.call(v)}%"
          cond.or :kana, 'LIKE', "%#{like_param.call(kana_v)}%"
          self.and cond
        end
      end
    end
  end

  def sorted_groups
    self.groups.sort do |g1, g2|
      names1 = g1.parents_tree_names
      names2 = g2.parents_tree_names
      comp = 0
      (0..([names1.size, names2.size].max - 1)).each do |i|
        comp = names1[i].to_s <=> names2[i].to_s
        break if comp != 0
      end
      comp
    end
  end
  
protected

  def save_groups

    gids = self.in_groups ? self.in_groups.split(",").collect{|id| id.to_i} : []
    grps = self.groupings;
    
    grps.each do |g|
      if idx = gids.index(g.group_id)
        gids.delete_at(idx)
      else
        g.destroy()
      end
    end
    
    gids.each do |gid|
      group = Gw::WebmailAddressGroup.new.readable
      group.and 'id', gid
      group.and 'user_id', Core.user.id
      group = group.find(:first)
      self.groupings << Gw::WebmailAddressGrouping.new({
        :address_id => id,
        :group_id => gid
      }) if group
    end
  end
  
end
