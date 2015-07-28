# encoding: utf-8
module Gw::MailboxHelper
  
  def mailbox_selection(mailboxes, options = {})
    options[:except] ||= []
    selection = []
    mailboxes.each do |box|
      selection << [box.slashed_title, box.id] if !options[:except].include?(box.name) 
    end
    selection
  end
end