require 'rails'
require "eventmachine"
require "redis"
require 'socket'

lib_dir = File.expand_path(File.dirname(__FILE__))

$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'cli'

require 'file_splitter'
require 'borg_abstract_adapter'
require 'borg_daemon'
require 'borg_config'
require 'borg_cucumber'
require 'borg_git'
require 'borg_messages'
require 'borg_requestor'
require 'borg_server'
require 'borg_test_unit'
require 'borg_worker'


module Borg
  class Railtie < Rails::Railtie
    config.after_initialize do
      Borg::Config.load_config("#{Rails.root}/config/borg.yml")
    end
    rake_tasks do
      load File.join(File.dirname(__FILE__),'borg_tasks.rake')
    end
  end
end
