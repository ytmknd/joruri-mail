module Gw::MailboxHelper
  def mailbox_selection(mailboxes, options = {})
    options[:except] ||= []
    selection = []
    mailboxes.each do |box|
      selection << [box.slashed_title, box.id] if !options[:except].include?(box.name) 
    end
    selection
  end

  def mailbox_list_class(mailbox)
    classes = []
    if mailbox.name =~ /^(INBOX|Drafts|Sent|Archives|Trash|Star)$/
      classes << mailbox.name.downcase
    else
      classes << 'folder'
    end
    if request.smart_phone?
      classes << "level#{mailbox.level_no}"
      classes << 'cursor' unless mailbox.trash_box?
    end
    classes.join(' ')
  end

  def mailbox_name_class(mailbox, current_mailbox)
    classes  = ['name']
    classes << 'current' if mailbox.name == current_mailbox.name
    classes << 'unseen' if mailbox.unseen > 0
    classes << 'droppable' if mailbox.name !~ /^(Drafts|Star)$/
    classes.join(' ')
  end

  def mailbox_mobile_image_tag(mailbox_type, options = {})
    postfix = "-blue" if options[:blue]
    img =
      case mailbox_type
      when 'inbox'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/transmit#{postfix}.jpg" alt="受信トレイ" />}
      when 'drafts'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/draft#{postfix}.jpg" alt="下書き" />}
      when 'sent'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/mailbox#{postfix}.jpg" alt="送信トレイ" />}
      when 'archives'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/archive#{postfix}.jpg" alt="アーカイブ" />}
      when 'trash'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/dustbox#{postfix}.jpg" alt="ごみ箱" />}
      when 'arvhives'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/archive#{postfix}.jpg" alt="アーカイブ" />}
      when 'star'
        %Q{<img src="/_common/themes/admin/gw/webmail/mobile/images/star#{postfix}.jpg" alt="スター付き" />}
      when 'folder'
        %Q{∟}
      else
        %Q{<img alt="フォルダ" src="/_common/themes/admin/gw/webmail/mobile/images/folder-white.jpg" alt="フォルダ" />}
      end
    img.html_safe
  end
end
