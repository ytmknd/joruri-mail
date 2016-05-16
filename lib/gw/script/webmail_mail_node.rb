class Gw::Script::WebmailMailNode
  
  def self.delete_caches(batch_size = 10000, sleep_sec = 1)
    puts "メールキャッシュ削除 開始"

    Gw::WebmailMailNode.where(ref_mailbox: nil).where('created_at < ?', Time.now).pluck(:id).each_slice(batch_size) do |ids|
      Gw::WebmailMailNode.where(id: ids).delete_all
      puts "#{ids.size}件削除"
      sleep sleep_sec
    end

    puts "メールキャッシュ削除 終了"
  end
end
