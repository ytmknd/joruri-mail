module Webmail::MailboxHelper
  def mailbox_list_class(mailbox)
    classes = ['folder']
    if mailbox.special_use.present?
      classes << mailbox.special_use.downcase
    elsif mailbox.inbox? || mailbox.virtual?
      classes << mailbox.name.downcase
    end
    if request.smart_phone?
      classes << "level#{mailbox.level_no}"
      classes << 'cursor' if !mailbox.noselect? && !mailbox.use_as_trash?
    end
    classes.join(' ')
  end

  def mailbox_name_class(mailbox, current_mailbox, options = {})
    classes  = ['name']
    classes << 'current' if mailbox.name == current_mailbox.name
    classes << 'unseen' if mailbox.unseen > 0 && !options[:without_unseen]
    classes << 'droppable' if mailbox.mail_droppable_box?
    classes.join(' ')
  end

  def mailbox_title(mailboxes, name)
    mailbox = mailboxes.detect { |box| box.name == name }
    mailbox.try(:title)
  end

  def mailbox_mobile_image_tag(mailbox)
    img =
      case
      when mailbox.inbox?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/transmit.jpg" alt="受信トレイ" />}
      when mailbox.virtual?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/folder-search.jpg" alt="検索" />}
      when mailbox.use_as_drafts?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/draft.jpg" alt="下書き" />}
      when mailbox.use_as_sent?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/mailbox.jpg" alt="送信トレイ" />}
      when mailbox.use_as_archive?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/archive.jpg" alt="アーカイブ" />}
      when mailbox.use_as_junk?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/junk.jpg" alt="迷惑メール" />}
      when mailbox.use_as_trash?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/dustbox.jpg" alt="ごみ箱" />}
      when mailbox.use_as_flagged?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/star.jpg" alt="スター付き" />}
      when mailbox.use_as_all?
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/transmit_open.jpg" alt="すべてのメール" />}
      else
        if mailbox.level_no == 0
          %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/folder-white.jpg" alt="フォルダー" />}
        else
          ''
        end
      end
    img.html_safe
  end
end
