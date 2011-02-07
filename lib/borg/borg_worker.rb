module Borg
  class Worker < EM::Connection
    include EM::P::ObjectProtocol
    @@status_reports = []
    
    def receive_object(ruby_object)
      case ruby_object
      when StartBuild
        update_code
      when StartTest
        start_test
      end
    end

    def connection_completed
      send_object(WorkerConnected.new(self.signature))
    end

    def unbind
      EM.add_timer(3) {
        reconnect(Borg::Config.ip,Borg::Config.port)
      }
    end

    def update_code
      source_control = Borg::Git.new()
      source_control.update(self)
    end
    
    def redis
      Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)
    end

    def code_updated(last_status)
      if(last_status.exit_status == 0)
        start_test
      else
        puts "sending error report"
        send_object(BuildStatus.new(1))
      end
    end

    def start_test
      if(redis.llen("tests") > 0)
        EM.popen("rake tickle:test RAILS_ENV=test", TestRunner) do |process|
          process.worker = self
          process.runner_type = 'unit'
        end
      else
        start_cucumber(BuildStatus.new(0))
      end
    end

    def start_cucumber(last_status)
      @@status_reports << last_status
      if(redis.llen("cucumber") > 0)
        EM.popen("rake tickle:cucumber RAILS_ENV=cucumber",TestRunner) do |process|
          process.worker = self
          process.runner_type = 'cucumber'
        end
      else
        send_final_report(BuildStatus.new(0))
      end
    end

    def send_final_report(last_status)
      @@status_reports << last_status
      p @@status_reports
      error_flag = @@status_reports.any? {|x| x.exit_status != 0}
      
      if(error_flag)
        send_object(BuildStatus.new(1))
      else
        send_object(BuildStatus.new(0))
      end
      @@status_reports = []
    end
  end

  class TestRunner < EM::Connection
    attr_accessor :worker
    attr_accessor :runner_type
    
    include EM::P::ObjectProtocol
    def receive_data(data)
      worker.send_object(BuildOutput.new(data))
    end

    def unbind
      puts "Sending the status thingy"
      case runner_type
      when 'unit'
        worker.start_cucumber(BuildStatus.new(get_status.exitstatus))
      when 'git'
        worker.code_updated(BuildStatus.new(get_status.exitstatus))
      else
        worker.send_final_report(BuildStatus.new(get_status.exitstatus))
      end
    end

  end
end
