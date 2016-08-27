class Webmail::Job < ApplicationJob
  def init_core(user)
    Core.initialize
    Core.user = Core.current_user = user
    yield
  ensure
    Core.terminate
  end

  def load_user(user_id, user_password)
    return unless user = Sys::User.find_by(id: user_id)
    user.password = Util::String::Crypt.decrypt(user_password)
    user
  end

  class << self
    def perform_later_as_user(user, options = {})
      perform_later(user.id, Util::String::Crypt.encrypt(user.password), options)
    end
  end
end
