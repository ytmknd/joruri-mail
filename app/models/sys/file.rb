class Sys::File < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::File

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

  class << self
    def new_tmp_id
      SecureRandom.hex(16)
    end

    def garbage_collect
      self.where.not(tmp_id: nil).where(parent_unid: nil)
        .where("created_at < ?", 2.days.ago)
        .find_each(&:destroy)
    end
  end
end
