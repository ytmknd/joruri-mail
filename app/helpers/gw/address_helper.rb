# coding: utf-8

module Gw::AddressHelper

  def show_address_groups(roots, &block)
    text = ''
    show_group = lambda do |item, indent|
      rtn = capture item, indent, &block
      item.children.each {|i| rtn += show_group.call(i, indent + 1)} if item.children.size > 0
      rtn
    end
    
    roots.each {|i| text += show_group.call(i, 0)}
    raw(text)
  end

  def show_actions?
    return true if controller.class == Gw::Admin::Webmail::AddressGroupsController
    false
  end
  
end