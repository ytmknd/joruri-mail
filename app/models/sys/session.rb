class Sys::Session < ApplicationRecord
  self.table_name = 'sessions'

  class << self
    def delete_past_sessions_at_random(rand_max = 10000)
      return unless rand(rand_max) == 0
      cleanup
    end

    def cleanup(exp = Joruri.config.application['sys.session_expiration'].to_i)
      if exp > 0
        self.where("updated_at < ?", exp.hours.ago).delete_all
      else
        0
      end
    end
  end
end
