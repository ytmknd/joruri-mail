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
      classes << 'cursor' unless mailbox.use_as_trash?
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

  def mailbox_mobile_image_tag(mailbox_type)
    img =
      case mailbox_type
      when 'inbox'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/transmit.jpg" alt="受信トレイ" />}
      when 'drafts'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/draft.jpg" alt="下書き" />}
      when 'sent'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/mailbox.jpg" alt="送信トレイ" />}
      when 'archives'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/archive.jpg" alt="アーカイブ" />}
      when 'trash'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/dustbox.jpg" alt="ごみ箱" />}
      when 'arvhives'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/archive.jpg" alt="アーカイブ" />}
      when 'virtual flagged'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/star.jpg" alt="スター付き" />}
      when 'folder'
        %Q{∟}
      else
        if mailbox_type =~ /^virtual\s/
          %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/folder-search.jpg" alt="検索" />}
        else
          %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/folder-white.jpg" alt="フォルダー" />}
        end
      end
    img.html_safe
  end
end
