class Webmail::MailNode < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  validates :user_id, :uid, :mailbox, presence: true

  before_create :encode_utf8mb4
  after_initialize :decode_utf8mb4

  def editable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end
  
  def deletable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  private

  def encode_utf8mb4
    [:from, :to, :cc, :bcc, :subject].each do |column|
      val = self.read_attribute(column)
      self[column] = Util::String.encode_utf8mb4(val) if val.present?
    end
  end

  def decode_utf8mb4
    [:from, :to, :cc, :bcc, :subject].each do |column|
      val = self.read_attribute(column)
      self[column] = Util::String.decode_utf8mb4(val) if val.present?
    end
  end

  class << self
    def delete_nodes(boxname, uids)
      self.where(user_id: Core.current_user.id, mailbox: boxname, uid: uids).delete_all
    end

    def delete_caches(batch_size = 10000, sleep_sec = 1)
      ids = self.where(ref_mailbox: nil).where('created_at < ?', Time.now).pluck(:id)
      ids.each_slice(batch_size) do |sliced_ids|
        self.where(id: sliced_ids).delete_all
        sleep sleep_sec
        yield sliced_ids if block_given?
      end
    end

    def delete_expired_caches(ex = Joruri.config.application['webmail.mail_cache_expiration'])
      self.where("created_at < ?", ex.months.ago).delete_all if ex > 0
    end
  end
end
