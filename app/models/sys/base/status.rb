# encoding: utf-8
require 'passive_record'
class Sys::Base::Status < PassiveRecord::Base

#  schema :id => String, :name => String
  define_fields :id, :name

#  create :enabled,        :name => '有効'
#  create :disabled,       :name => '無効'
#  create :visible,        :name => '表示'
#  create :hidden,         :name => '非表示'
#  create :draft,          :name => '下書き'
#  create :recognize,      :name => '承認待ち'
#  create :recognized,     :name => '公開待ち'
#  create :prepared,       :name => '公開'
#  create :public,         :name => '公開中'
#  create :closed,         :name => '非公開'
#  create :completed,      :name => '完了'

  def name
    case id
    when 'enabled';    return '有効'
    when 'disabled';   return '無効'
    when 'visible';    return '表示'
    when 'hidden';     return '非表示'
    when 'draft';      return '下書き'
    when 'recognize';  return '承認待ち'
    when 'recognized'; return '公開待ち'
    when 'prepared';   return '公開'
    when 'public';     return '公開中'
    when 'closed';     return '非公開'
    when 'completed';  return '完了'
    end
    nil
  end
  
  def self.find(*args)
    instance = self.new
    instance.id = args[0]
    instance
  end
  
  def to_xml(options = {})
    options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

    _root = options[:root] || 'status'

    xml = options[:builder]
    xml.tag!(_root) { |n|
      n.id   key.to_s
      n.name name.to_s
    }
  end
end