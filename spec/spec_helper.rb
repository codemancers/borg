require "rubygems"
$:<< File.join(File.dirname(__FILE__),"..","lib")
require "borg"
require "borg/borg_config"

Borg::Config.redis_ip = "localhost"
Borg::Config.redis_port = 6379

module Helpers
  def redis
    Redis.new(:host => Borg::Config.redis_ip, :port => Borg::Config.redis_port)
  end
end
