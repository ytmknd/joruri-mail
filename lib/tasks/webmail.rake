namespace :webmail do
  desc 'Cleanup unnecessary or expired data'
  task :cleanup => :environment do
    Sys::File.garbage_collect
    Sys::Session.delete_expired_sessions
  end

  desc 'Delete mail caches'
  task :delete_mail_caches => :environment do
    Gw::WebmailMailNode.delete_caches do |ids|
      puts "#{ids.size} deleted"
    end
  end
end
