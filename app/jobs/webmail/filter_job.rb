class Webmail::FilterJob < Webmail::Job
  queue_as :filter

  def perform(user_id, user_password, opts)
    return unless user = load_user(user_id, user_password)

    init_core(user) do
      filters = Webmail::Filter.where(user_id: user.id, state: 'enabled').order(:sort_no, :id)
        .preload(:conditions)
      Webmail::Filter.apply_uids(filters, mailbox: opts[:mailbox], uids: opts[:uids])
    end
  end
end
