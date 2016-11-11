namespace :sys do
  namespace :ldap_synchro do
    desc "Run ldap synchro"
    task run: :environment do
      task = Sys::LdapSynchroTask.run
      stdout_log "ldap fetch [ #{task.fetch_log} ], synchro [ #{task.synchro_log} ]"
    end
  end
end
