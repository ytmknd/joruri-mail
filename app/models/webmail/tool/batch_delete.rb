class Webmail::Tool::BatchDelete
  include ActiveModel::Model

  attr_accessor :mailbox_id, :start_date, :end_date
  attr_accessor :include_starred

  validates :mailbox_id, presence: true
  validates :start_date, :end_date, format: { with: /\A\d{4}-\d{2}-\d{2}\z/ }, date_time: true

  def batch_delete_mails(mailboxes)
    delete_num = 0
    changed_mailboxes = []

    mailbox_id = self.mailbox_id.to_i
    sent_since = Time.parse(self.start_date).strftime("%d-%b-%Y")
    sent_before = (Time.parse(self.end_date) + 1.days).strftime("%d-%b-%Y")

    mailboxes.each do |mailbox|
      next unless mailbox.batch_deletable_box?
      next if mailbox_id != 0 && mailbox_id != mailbox.id 

      condition = ['SENTSINCE', sent_since, 'SENTBEFORE', sent_before]
      condition << 'UNFLAGGED' if self.include_starred == '0'

      Core.imap.select(mailbox.name)
      uids = Core.imap.uid_search(condition)
      delete_num += mailbox.delete_mails(uids)
    end

    if delete_num > 0
      Webmail::Mailbox.load_mailboxes(:all)
      Webmail::Mailbox.load_quota(true)
    end

    delete_num
  end
end
