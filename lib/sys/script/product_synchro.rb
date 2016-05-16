class Sys::Script::ProductSynchro

  def self.check
    puts "プロダクト同期 定期チェック"

    item = System::ProductSynchro.joins(:product)
      .where('system_products.product_type = ?', 'mail')
      .where('system_product_synchros.state = ?', 'start')
      .order('system_product_synchros.created_at').first
    return if item.blank?

    puts "プロダクト同期 開始"

    item.execute

    puts "プロダクト同期 終了"
  end
end
