# encoding: utf-8

## ---------------------------------------------------------
## methods

def truncate_table(table)
  puts "TRUNCATE TABLE #{table}"
  ActiveRecord::Base.connection.execute "TRUNCATE TABLE #{table}"
end

def load_seed_file(file)
  load "#{Rails.root}/db/seed/#{file}"
end

## ---------------------------------------------------------
## truncate

dir = "#{Rails.root}/db/seed/base" 
Dir::entries(dir).each do |file|
  next if file !~ /\.rb$/
  load_seed_file "base/#{file}"
end

## ---------------------------------------------------------
## load config

core_uri   = Util::Config.load :core, :uri
core_title = Util::Config.load :core, :title
map_key    = Util::Config.load :core, :map_key

## ---------------------------------------------------------
## sys

Sys::Group.create({
  :parent_id => 0,
  :level_no  => 1,
  :sort_no   => 1,
  :state     => 'enabled',
  :web_state => 'closed',
  :ldap      => 0,
  :code      => "root",
  :name      => "組織",
  :name_en   => "soshiki"
})

Sys::User.create({
  :state           => 'enabled',
  :ldap            => 0,
  :auth_no         => 5,
  :name            => "システム管理者",
  :account         => "admin",
  :password        => "admin",
  :mobile_access   => 1,
  :mobile_password => "admin",
  :email           => "admin@demo.joruri.org"
})

Sys::UsersGroup.create({
  :user_id  => 1,
  :group_id => 1
})

Core.user       = Sys::User.find_by_account('admin')
Core.user_group = Core.user.groups[0]

## ---------------------------------------------------------
## cms

Sys::Language.create({
  :state   => 'enabled',
  :sort_no => 1,
  :name    => 'japanese',
  :title   => '日本語'
})

###site = Cms::Site.create({
###  :state    => 'public',
###  :name     => core_title,
###  :full_uri => core_uri,
###  :node_id  => 1,
###  :map_key  => map_key
###})

#Cms::Concept.create({
#  :site_id   => 1,
#  :parent_id => 0,
#  :state     => 'public',
#  :level_no  => 1,
#  :sort_no   => 1,
#  :name      => core_title
#})
#
#d = Cms::Node.create({
#  :site_id      => 1,
#  :concept_id   => 1,
#  :parent_id    => 0,
#  :route_id     => 0,
#  :state        => 'public',
#  :published_at => Time.now,
#  :directory    => 1,
#  :model        => 'Cms::Directory',
#  :name         => '/',
#  :title        => core_title
#})
#Cms::Node.create(d.attributes.merge({
#  :parent_id    => 1,
#  :route_id     => 1,
#  :directory    => 0,
#  :model        => 'Cms::Page',
#  :name         => 'index.html'
#}))

puts "Imported base data."
