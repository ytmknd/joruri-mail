require 'nkf'

Dir[Rails.root.join('lib/plugins/joruri/**/*.rb')].each {|file| require file }
