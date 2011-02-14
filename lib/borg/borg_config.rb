module Borg
  class Config
    cattr_accessor :ip,:port
    cattr_accessor :redis_ip, :redis_port
    cattr_accessor :cucumber_processes, :test_unit_processes, :rspec_processes
  end
end

