require 'digest/md5'
class Sys::File < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::File

  def self.garbage_collect
    self.where.not(tmp_id: nil).where(parent_unid: nil)
      .where("created_at < ?", Date.strptime(Core.now, "%Y-%m-%d") - 2)
      destroy_all
  end

  def self.fix_tmp_files(tmp_id, parent_unid)
    self.where(parent_unid: nil, tmp_id: tmp_id).update_all(parent_unid: parent_unid, tmp_id: nil)
  end

  def self.new_tmp_id
    connection.execute("INSERT INTO #{table_name} (id, tmp_id) VALUES (null, 0)")
    id = find_by_sql("SELECT LAST_INSERT_ID() AS id")[0].id
    connection.execute("DELETE FROM #{table_name} WHERE id = #{id}")
    Digest::MD5.new.update(id.to_s)
  end

  def duplicated?
    rel = self.class.where(name: name)
    rel = rel.where.not(id: id) if id
    if tmp_id
      rel = rel.where(tmp_id: tmp_id)
      rel = rel.where(parent_unid: nil)
    else
      rel = rel.where(tmp_id: nil)
      rel = rel.where(parent_unid: parent_unid)
    end
    rel.first
  end
end
