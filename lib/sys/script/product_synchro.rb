# encoding: utf-8
class Sys::Script::ProductSynchro
  
  def self.check
    puts "プロダクト同期 定期チェック"
    
    item = System::ProductSynchro.new
    item.and 'system_products.product_type', 'mail'
    item.and 'system_product_synchros.state', 'start'
    item = item.find(:first, :joins => :product, :readonly => false, :order => 'system_product_synchros.created_at')
    return if item.blank?
    
    puts "プロダクト同期 開始"
    
    item.execute
    
    puts "プロダクト同期 終了"
  end
end
