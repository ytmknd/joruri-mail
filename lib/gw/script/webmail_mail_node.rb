# encoding: utf-8
class Gw::Script::WebmailMailNode
  
  def self.delete_caches(batch_size = 10000, sleep_sec = 1)
    puts "メールキャッシュ削除 開始"
    
    cond = Condition.new
    cond.and :ref_mailbox, 'IS', nil
    cond.and :created_at, '<', Time.now
    
    Gw::WebmailMailNode.find_in_batches(:conditions => cond.where, :select => 'id', :batch_size => batch_size) do |items|
      Gw::WebmailMailNode.delete_all(:id => items.map(&:id))
      puts "#{items.size}件削除"
      sleep sleep_sec
    end
    
    puts "メールキャッシュ削除 終了"
  end
end