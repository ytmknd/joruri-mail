namespace :system do
  namespace :product_synchro do
    desc 'Check product synchro on Gw'
    task :check => :environment do
      System::ProductSynchro.check
    end
  end
end
