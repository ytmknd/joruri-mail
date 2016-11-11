class Sys::Tenant < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Manager

  has_one :root_group, -> { where(level_no: 1) },
    primary_key: :code, foreign_key: :tenant_code, class_name: 'Sys::Group'

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  enumerize :default_pass_limit, in: [:enabled, :disabled]
  enumerize :mobile_access, in: [1, 0]

  def mail_domains
    domains = []
    domains << Core.config['mail_domain'] if Core.config && Core.config['mail_domain'].present?
    domains += mail_domain.to_s.split(/[,\s\r\n]+/)
    domains
  end
end
