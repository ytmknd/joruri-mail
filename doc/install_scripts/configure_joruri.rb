#!/usr/bin/env ruby
DONE_FLAG = "/tmp/#{$0}_done"

puts '#### Configure Joruri ####'
exit if File.exist?(DONE_FLAG)
puts '-- PRESS ENTER KEY --'
gets

require 'fileutils'
require 'yaml/store'

def bundle_exec(command)
  `su - joruri -c "cd /var/share/jorurimail && bundle exec #{command}"`
end

def replace(filename)
  File.open(filename, File::RDWR) do |f|
    f.flock(File::LOCK_EX)
    data = f.read
    f.rewind
    data = yield data
    f.write data
    f.flush
    f.truncate(f.pos)
    f.flock(File::LOCK_UN)
  end
end

def ubuntu
  puts 'Ubuntu will be supported shortly.'
end

def centos
  puts "It's CentOS!"

  config_dir = '/var/share/jorurimail/config/'

  # set core.yml
  yml = YAML::Store.new("#{config_dir}core.yml")
  yml.transaction do
    yml['production']['uri'] = "http://#{`hostname`.chomp}/"
  end

  # set secrets.yml
  secret = bundle_exec("rake secret RAILS_ENV=production")
  replace("#{config_dir}secrets.yml") do |data|
    data.gsub('<%= ENV["SECRET_KEY_BASE"] %>', secret)
  end

  # set virtual-hosts
  joruri_conf = "#{config_dir}virtual-hosts/jorurimail.conf"
  replace(joruri_conf) do |data|
    data.gsub('jorurimail.example.com', `hostname`.chomp)
  end
  system "ln -s #{joruri_conf} /etc/httpd/conf.d/jorurimail.conf"

  # create database
  system 'service mysqld start'
  sleep 1 until system 'mysqladmin ping' # Not required to connect
  system "/usr/bin/mysql -u root -ppass -e 'create database jorurimail'"
  system %q!mysql -u root -ppass -e "GRANT ALL ON jorurimail.* TO joruri@localhost IDENTIFIED BY 'pass'"!
  bundle_exec "rake db:schema:load RAILS_ENV=production"
  bundle_exec "rake db:seed RAILS_ENV=production"
  bundle_exec "rake db:seed:demo RAILS_ENV=production"
  system 'service mysqld stop'

  # install and compile assets
  bundle_exec "rake bower:install RAILS_ENV=production"
  bundle_exec "rake assets:precompile RAILS_ENV=production"

  # set cron task
  bundle_exec "whenever -i -s 'environment=production'"
end

def others
  puts 'This OS is not supported.'
  exit
end

if __FILE__ == $0
  if File.exist? '/etc/centos-release'
    centos
  elsif File.exist? '/etc/lsb-release'
    unless `grep -s Ubuntu /etc/lsb-release`.empty?
      ubuntu
    else
      others
    end
  else
    others
  end

  system "touch #{DONE_FLAG}"
end
