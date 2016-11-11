namespace :webmail do
  desc 'Cleanup unnecessary or expired data'
  task :cleanup => :environment do
    Sys::File.garbage_collect
    Sys::Session.delete_expired_sessions
    Sys::LdapSynchroTask.cleanup
    Webmail::MailNode.delete_expired_caches
  end

  desc 'Delete mail caches'
  task :delete_mail_caches => :environment do
    Webmail::MailNode.delete_all
  end
end
