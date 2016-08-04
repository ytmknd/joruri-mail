class Webmail::Template < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  validates :user_id, :name, presence: true
  validates :to, :cc, :bcc, email_list: true

  after_save :uniq_default_flag, if: :default_flag?

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  enumerize :default_flag, in: { set: 1, unset: 0 }

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  private

  def uniq_default_flag
    self.class.where(user_id: Core.user.id).where.not(id: id).update_all(default_flag: 0)
  end

  class << self
    def default_template
      self.where(user_id: Core.user.id, default_flag: 1).first
    end
  
    def user_templates
      self.where(user_id: Core.user.id).order(:name, :id)
    end
  end
end
