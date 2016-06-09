class Gw::WebmailAddress < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  has_many :groupings, foreign_key: :address_id, class_name: 'Gw::WebmailAddressGrouping',
    dependent: :destroy
  has_many :groups, -> { order(:name, :id) }, through: :groupings

  attr_accessor :easy_entry, :escaped

  validates :user_id, :name, :email, presence: true
  validate :validate_attributes

  before_save :replace_name
  before_save :replace_kana

  #CONSTANTS
  NO_GROUP = 'no_group'

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }
  scope :search, ->(params) {
    rel = all
    params.each do |k, vs|
      next if vs.blank?
      vs.split(/[ 　]+/).each do |v|
        next if v == ''
        case k
        when 's_group_id'
          rel = rel.where(group_id: v == NO_GROUP ? nil : v)
        when 's_name'
          rel = rel.where(arel_table[:name].matches("%#{escape_like(v)}%"))
        when 's_email'
          rel = rel.where(arel_table[:email].matches("%#{escape_like(v)}%"))
        when 's_name_or_kana'
          kana_v = v.to_s.tr("ぁ-ん", "ァ-ン")
          rel = rel.where([
            arel_table[:name].matches("%#{escape_like(v)}%"),
            arel_table[:kana].matches("%#{escape_like(kana_v)}%"),
          ].reduce(:or))
        end
      end
    end
    rel
  }

  def self.user_addresses
    self.where(user_id: Core.user.id)  
  end

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def sorted_groups
    self.groups.sort do |g1, g2|
      names1 = g1.ancestors.map(&:name)
      names2 = g2.ancestors.map(&:name)
      comp = 0
      (0..([names1.size, names2.size].max - 1)).each do |i|
        comp = names1[i].to_s <=> names2[i].to_s
        break if comp != 0
      end
      comp
    end
  end

  private

  def validate_attributes
    if easy_entry # from Ajax
      if email.present? && name.present?
        if self.class.where(user_id: Core.user.id, email: email).first
          errors.add(:base, "既に登録されています。")
        else
          self.name  = CGI.unescapeHTML(name.to_s) if escaped
          self.name  = name.gsub(/^"(.*)"$/, '\\1')
          self.email = email
        end
      end
    end
  end

  def replace_name
    self.name = name.gsub(/["<>]/, '') if name.present?
  end

  def replace_kana
    to_kana = lambda {|str| str.to_s.tr("ぁ-ん", "ァ-ン") }
    self.kana = to_kana.call(kana) if kana.present?
    self.company_kana = to_kana.call(company_kana) if company_kana.present?
  end
end
