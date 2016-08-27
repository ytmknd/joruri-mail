class Webmail::QuotaRoot < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  def display_info
    usage_bytes = usage.to_i*1024
    quota_bytes = quota.to_i*1024
    warn_bytes = quota_bytes * Joruri.config.application['webmail.mailbox_quota_alert_rate'].to_f

    hash = HashWithIndifferentAccess.new
    hash[:total_bytes] = quota_bytes
    hash[:total]       = human_size(quota_bytes)
    hash[:used_bytes]  = usage_bytes
    hash[:used]        = human_size(usage_bytes)
    hash[:usage_rate]  = sprintf('%.1f', usage_bytes.to_f / quota_bytes.to_f * 100).to_f
    hash[:usable]      = human_size(quota_bytes - usage_bytes) if usage_bytes > warn_bytes 
    hash
  end

  private

  def human_size(num)
    ApplicationController.helpers.number_to_human_size(num, precision: 0, locale: :en)
  end

  class << self
    def load_quota(reload = false)
      return unless imap.capabilities.include?('QUOTA')

      item = self.where(user_id: Core.current_user.id).first_or_initialize
      return item.display_info if !reload && item.persisted?

      res = imap.getquotaroot('INBOX')[1]
      return unless res

      item.update_attributes(
        mailbox: res.mailbox,
        usage: res.usage.to_i,
        quota: res.quota.to_i
      )
      item.display_info
    end

    private

    def imap
      Core.imap
    end
  end
end
