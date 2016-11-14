namespace :sys do
  desc 'Cleanup unnecessary or expired data'
  task :cleanup => :environment do
    num = Sys::Session.cleanup
    stdout_log "sessions: #{num} deleted."
    num = Sys::File.cleanup
    stdout_log "sys_files: #{num} deleted."
    num = Sys::LdapSynchroTask.cleanup
    stdout_log "sys_ldap_synchro_tasks: #{num} deleted."

    Rake::Task['webmail:cleanup'].invoke
  end

  namespace :ldap_synchro do
    desc "Run ldap synchro"
    task run: :environment do
      task = Sys::LdapSynchroTask.run
      stdout_log "ldap fetch [ #{task.fetch_log} ], synchro [ #{task.synchro_log} ]"
    end
  end
end
