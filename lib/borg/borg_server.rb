module Borg
  class Server < EM::Connection
    include EM::P::ObjectProtocol
    @@workers = {}
    @@requester = {}

    @@status_count = 0
    @@status_reports = []
    attr_accessor :client_type

    def receive_object(ruby_object)
      case ruby_object
      when BuildOutput
        send_to_requester(ruby_object)
      when BuildStatus
        puts "Received object #{ruby_object.inspect}"
        collect_status_response(ruby_object)
      when WorkerConnected
        @@workers[self.signature] = self
        @client_type = :worker
      when BuildRequester
        @@requester[self.signature] = self
        @client_type = :requestor
        check_for_workers && add_tests_to_redis && start_build(ruby_object)
      end
    end

    def check_for_workers
      return true unless @@workers.empty?
      send_error_to_requester("No worker found running")
      false
    end

    def send_error_to_requester(message)
      send_to_requester(BuildOutput.new(message))
      send_to_requester(BuildStatus.new(1))
    end

    def add_tests_to_redis
      begin
        TestUnit.new().add_to_redis(@@workers.size * 3)
        CucumberRunner.new().add_to_redis(@@workers.size * 1)
        true
      rescue
        puts $!.message
        puts $!.backtrace
        send_error_to_requester("Error adding files to redis")
        false
      end
    end

    def collect_status_response(ruby_object)
      @@status_reports << ruby_object
      @@status_count -= 1
      puts "Status count is #{@@status_count}"
      if(@@status_count == 0)
        error_status = @@status_reports.any? {|x| x.exit_status != 0 }
        @@status_reports = []
        if(error_status)
          send_to_requester(BuildStatus.new(1))
        else
          send_to_requester(BuildStatus.new(0))
        end
      end
    end

    def unbind
      @@workers.delete(self.signature)
      @@requester.delete(self.signature)
      if(client_type == :requestor)
        @@status_count = 0
        @@status_reports = []
      end
    end

    def start_build(build_request)
      @@workers.each do |key,worker|
        @@status_count += 1
        worker.send_object(StartBuild.new(build_request.sha))
      end
    end

    def send_to_requester(ruby_object)
      @@requester.each do |key,requester|
        requester.send_object(ruby_object)
      end
    end
  end
end
