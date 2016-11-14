namespace :webmail do
  desc 'Cleanup unnecessary or expired data'
  task :cleanup => :environment do
    num = Webmail::MailNode.cleanup
    stdout_log "webmail_mail_nodes: #{num} deleted."
  end

  desc 'Delete mail caches'
  task :delete_mail_caches => :environment do
    Webmail::MailNode.delete_all
  end
end
