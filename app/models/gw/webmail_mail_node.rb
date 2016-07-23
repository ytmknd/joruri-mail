class Gw::WebmailMailNode < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  validates :user_id, :uid, :mailbox, presence: true

  scope :readable, ->(user = Core.current_user) { where(user_id: user.id) }

  def editable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end
  
  def deletable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  class << self
    def find_nodes(boxname, uids = nil)
      items = self.where(user_id: Core.current_user.id, mailbox: boxname)
      items = items.where(uid: uids) if uids
      items
    end

    def find_ref_nodes(boxname, uids = nil)
      items = self.where(user_id: Core.current_user.id, ref_mailbox: boxname)
      items = items.where(ref_uid: uids) if uids
      items
    end

    def delete_nodes(boxname, uids = nil)
      items = self.where(user_id: Core.current_user.id, mailbox: boxname)
      items = items.where(uid: uids) if uids
      items.delete_all
    end

    def delete_ref_nodes(boxname, uids = nil)
      items = self.where(user_id, Core.current_user.id, ref_mailbox: boxname)
      items = items.where(ref_uid: uids) if uids
      items.delete_all
    end

    def delete_caches(batch_size = 10000, sleep_sec = 1)
      ids = self.where(ref_mailbox: nil).where('created_at < ?', Time.now).pluck(:id)
      ids.each_slice(batch_size) do |sliced_ids|
        self.where(id: sliced_ids).delete_all
        sleep sleep_sec
        yield sliced_ids if block_given?
      end
    end
  end
end
