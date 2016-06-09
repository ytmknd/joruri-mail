namespace :webmail do
  desc 'Cleanup unnecessary or expired data'
  task :cleanup => :environment do
    Sys::File.garbage_collect
    Sys::Session.delete_expired_sessions
  end
end
