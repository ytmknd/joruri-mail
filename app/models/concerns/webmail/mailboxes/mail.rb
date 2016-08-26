module Webmail::Mailboxes::Mail
  def paginate_mails(options)
    Webmail::Mail.paginate(options.merge(select: name))
  end

  def paginate_mail_by_uid(uid, options)
    Webmail::Mail.paginate_by_uid(uid, options.merge(select: name))
  end

  def find_mails(options)
    Webmail::Mail.find(options.merge(select: name))
  end

  def find_mail_by_uid(uid, options)
    Webmail::Mail.find_by_uid(uid, options.merge(select: name))
  end

  def move_mails(dest_name, uids)
    Webmail::MailNode.delete_nodes(name, uids)
    Webmail::Mail.move_all(name, dest_name, uids)
  end

  def copy_mails(dest_name, uids)
    Webmail::Mail.copy_all(name, dest_name, uids)
  end

  def trash_mails(trash_name, uids)
    Webmail::MailNode.delete_nodes(name, uids)
    if trash_box?
      Webmail::Mail.delete_all(name, uids)
    else
      Webmail::Mail.move_all(name, trash_name, uids)
    end
  end

  def delete_mails(uids)
    Webmail::MailNode.delete_nodes(name, uids)
    Webmail::Mail.delete_all(name, uids)
  end

  def empty_mails
    imap.select(name)
    uids = imap.uid_search(['UNDELETED'], 'utf-8')
    delete_mails(uids)
  end

  def answered_mails(uids)
    Webmail::Mail.answered_all(name, uids)
  end

  def forwarded_mails(uids)
    Webmail::Mail.forwarded_all(name, uids)
  end

  def seen_mails(uids)
    Webmail::Mail.seen_all(name, uids)
  end

  def unseen_mails(uids)
    Webmail::Mail.unseen_all(name, uids)
  end

  def star_mails(uids)
    Webmail::Mail.star_all(name, uids)
  end

  def unstar_mails(uids)
    Webmail::Mail.unstar_all(name, uids)
  end

  def label_mails(uids, label_id = nil)
    Webmail::Mail.label_all(name, uids, label_id)
  end

  def unlabel_mails(uids, label_id = nil)
    Webmail::Mail.unlabel_all(name, uids, label_id)
  end
end
