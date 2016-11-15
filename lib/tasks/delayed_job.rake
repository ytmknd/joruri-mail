namespace :delayed_job do
  def delayed_job
    "RAILS_ENV=#{Rails.env} bin/delayed_job"
  end

  def delayed_job_options
    "--monitor"
  end

  def delayed_job_pids
    Dir["#{Rails.root}/tmp/pids/delayed_job*.pid"].map do |file|
      File.read(file).to_i
    end
  end

  desc 'Start delayed job'
  task start: :environment do
    sh "#{delayed_job} start #{delayed_job_options}"
  end

  desc 'Stop delayed job'
  task stop: :environment do
    sh "#{delayed_job} stop #{delayed_job_options}"
  end

  desc 'Restart delayed job'
  task restart: :environment do
    sh "#{delayed_job} restart #{delayed_job_options}"
  end

  desc 'Check delayed job status'
  task status: :environment do
    sh "#{delayed_job} status #{delayed_job_options}"
  end

  desc 'Monitor delayed job memory'
  task monitor: :environment do
    pids = delayed_job_pids
    next if pids.blank?
    procs = `ps -p #{pids.join(',')} -o pid,rss -h`.split("\n").map(&:split)
    mems = procs.map { |p| p[1].to_i }
    if mems.any? { |mem| mem > 1024*1024 } && !Delayed::Job.where.not(locked_at: nil).exists?
      Rake::Task['delayed_job:restart'].invoke
    end
  end
end
