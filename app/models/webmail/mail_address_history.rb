class Webmail::MailAddressHistory < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Tree
  include Sys::Model::Auth::Free

  attr_accessor :display_name

  def email_format
    if display_name
      "#{Email.quote_phrase(display_name)} <#{address}>"
    else
      address
    end
  end

  class << self
    def save_user_histories(addresses)
      addresses.each do |addr|
        self.create(
          user_id: Core.current_user.id, 
          address: addr.address, 
          friendly_address: addr.to_s
        )
      end

      delete_exceeded_histories
    end

    def delete_exceeded_histories
      max_count = Joruri.config.application['webmail.mail_address_history_max_count']
      curr_count = self.where(user_id: Core.current_user.id).count

      if curr_count > max_count
        self.connection.execute(
          "DELETE FROM webmail_mail_address_histories 
            WHERE user_id = #{Core.current_user.id} ORDER BY created_at LIMIT #{curr_count - max_count}"
        )
      end
    end

    def load_user_histories(count)
      items = self.select('count(*) as count, address')
        .where(user_id: Core.current_user.id)
        .group(:address)
        .limit(count)
        .order('count DESC, created_at DESC')

      emails = items.map(&:address)
      address_map = load_address_map(emails)
      sys_address_map = load_sys_address_map(emails)

      items.each do |item|
        if name = address_map[item.address]
          item.display_name = name
        elsif name = sys_address_map[item.address]
          item.display_name = name
        end
      end
      items
    end

    def load_address_map(emails)
      addrs = Webmail::Address.where(email: emails, user_id: Core.current_user.id).pluck(:email, :name).flatten
      Hash[*addrs]
    end

    def load_sys_address_map(emails)
      addrs = Sys::User.enabled_users_in_tenant.where(email: emails).pluck(:email, :name).flatten
      Hash[*addrs]
    end
  end
end
