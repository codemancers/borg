require "rubygems"
$:<< File.join(File.dirname(__FILE__),"..","lib")
require "borg"

module Rails
  def self.root
    File.join(File.dirname(__FILE__),"sample_app")
  end
end

Borg::Config.load_config(File.join(Rails.root, "config/borg.yml"))

module Helpers
  def redis
    Redis.new(:host => Borg::Config.redis_ip, :port => Borg::Config.redis_port)
  end
end
