namespace :sys do
  namespace :ldap_synchro do
    desc "Run ldap synchro"
    task run: :environment do
      results = Sys::LdapSynchro.run

      puts "グループ"
      puts "-- 更新 #{results[:group]}件"
      puts "-- 削除 #{results[:gdel]}件" if results[:gdel].present?
      puts "-- 失敗 #{results[:gerr]}件" if results[:gerr].present?
      puts "ユーザー"
      puts "-- 更新 #{results[:user]}件"
      puts "-- 削除 #{results[:udel]}件" if results[:udel].present?
      puts "-- 失敗 #{results[:uerr]}件" if results[:uerr].present?
    end
  end
end
