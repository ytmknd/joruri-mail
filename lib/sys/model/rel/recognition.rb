# encoding: utf-8
module Sys::Model::Rel::Recognition
  def self.included(mod)
    mod.belongs_to :recognition, :foreign_key => 'unid', :class_name => 'Sys::Recognition',
      :dependent => :destroy

    mod.after_save :save_recognition
  end

  attr_accessor :in_recognizer_ids
  
  def in_recognizer_ids
    unless read_attribute(:in_recognizer_ids)
      write_attribute(:in_recognizer_ids, recognizer_ids.to_s)
    end
    read_attribute(:in_recognizer_ids)
  end
  
  def in_recognizer_ids=(ids)
    @_in_recognizer_ids_changed = true
    write_attribute(:in_recognizer_ids, ids.to_s)
  end
  
  def recognizer_ids
    recognition ? recognition.recognizer_ids : ''
  end
  
  def recognizers
    recognition ? recognition.recognizers : []
  end
  
  def join_recognition
    join :recognition
  end
  
  def recognized?
    return state == 'recognized'
  end

  def recognizable
    join_creator
    join_recognition

    cond = Condition.new do |c|
      c.or 'sys_recognitions.recognizer_ids', 'REGEXP', "(^| )#{Core.user.id}( |$)"
      c.or "sys_recognitions.user_id", Core.user.id
    end
    self.and cond
    self.and "#{self.class.table_name}.state", 'recognize'
    
    return self
  end

  def recognizable?(user = nil)
    return false unless recognition
    recognition.recognizable?(user)
  end

  def recognize(user)
    return false unless recognition
    rs = recognition.recognize(user)
    if state == 'recognize' && recognition.recognized_all?
      sql = "UPDATE #{self.class.table_name} SET state = 'recognized', recognized_at = 'Core.now' WHERE id = #{id}"
      self.state = 'recognized'
      self.recognized_at = Core.now
      self.class.connection.execute(sql)
    end
    return rs
  end

private
  def validate_recognizers
    errors.add "承認者", :empty if in_recognizer_ids.blank?
  end
  
  def save_recognition
    return true unless @_in_recognizer_ids_changed
    return false unless unid
    return false if @sent_save_recognition
    @sent_save_recognition = true
    
    rec = recognition || Sys::Recognition.new
    rec.user_id        = Core.user.id
    rec.recognizer_ids = in_recognizer_ids.strip
    rec.info_xml       = nil
    
    if rec.id
      rec.save
    else
      rec.id         ||= unid
      rec.created_at   = Core.now
      rec.updated_at   = Core.now
      rec.save_with_direct_sql
      rec = Sys::Recognition.find_by_id(rec.id)
    end
    rec.reset_info
    
    sql = "UPDATE #{self.class.table_name} SET recognized_at = NULL WHERE id = #{id}"
    self.recognized_at = nil
    self.class.connection.execute(sql)
    
    return true
  end
end