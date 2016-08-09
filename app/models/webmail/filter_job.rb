class Webmail::FilterJob
  attr_accessor :user_id, :user_password, :mailbox, :uids

  def initialize(attrs = {})
    self.user_id = attrs[:user].id
    self.user_password = Util::String::Crypt.encrypt(attrs[:user].password)
    self.mailbox = attrs[:mailbox]
    self.uids = attrs[:uids]
  end

  def perform
    return unless user = load_user

    init_core(user) do
      filters = Webmail::Filter.where(user_id: user.id, state: 'enabled').order(:sort_no, :id)
        .preload(:conditions)
      Webmail::Filter.apply_uids(filters, mailbox: mailbox, uids: uids)
    end
  end

  private

  def load_user
    if user = Sys::User.find_by(id: user_id)
      user.password = Util::String::Crypt.decrypt(user_password)
      user
    end
  end

  def init_core(user)
    Core.initialize
    Core.user = Core.current_user = user
    yield
  ensure
    Core.terminate
  end
end
