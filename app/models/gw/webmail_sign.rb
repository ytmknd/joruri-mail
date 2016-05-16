class Gw::WebmailSign < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  validates :user_id, :name, presence: true

  after_save :uniq_default_flag, if: %Q(default_flag == 1)

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  private

  def uniq_default_flag
    self.class.where(user_id: Core.user.id).where.not(id: id).update_all(default_flag: 0)
    return true
  end

  class << self
    def default_sign
      self.where(user_id: Core.user.id, default_flag: 1).first
    end
  
    def user_signs
      self.where(user_id: Core.user.id).order(:name, :id)
    end
  end
end
