module Borg
  class Config
    cattr_accessor :ip,:port
    cattr_accessor :redis_ip, :redis_port
  end
end

