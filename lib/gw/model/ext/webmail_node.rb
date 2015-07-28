# encoding: utf-8
module Gw::Model::Ext::WebmailNode
  def date(format = '%Y-%m-%d %H:%M', nullif = nil)
    @node.message_date.blank? ? nullif : @node.message_date.strftime(format)
  end
  
  def friendly_from_addr
    @node.from
  end
  
  def friendly_to_addrs
    @node.to.to_s.split("\n")
  end
  
  def friendly_cc_addrs
    @node.cc.to_s.split("\n")
  end
  
  def friendly_bcc_addrs
    @node.bcc.to_s.split("\n")
  end
  
  def subject
    @node.subject
  end
  
  def has_attachments?
    @node.has_attachments
  end
  
  def size
    @node.size
  end
  
  def has_disposition_notification_to?
    @node.has_disposition_notification_to?
  end
  
  def move(to_mailbox)
    return true if mailbox == to_mailbox
    @node.destroy if @node
    return super(to_mailbox)
  end
  
  def destroy(complete = false)
    @node.destroy if @node
    return super(complete)
  end
end