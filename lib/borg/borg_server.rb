module Borg
  class Server < EM::Connection
    include EM::P::ObjectProtocol
    cattr_accessor :workers, :requestors, :status_count, :status_reports

    self.workers = {}
    self.requestors = {}

    self.status_count = 0
    self.status_reports = []

    class << self
      def worker_ips
        self.workers.values.map do |worker_data|
          worker_data.worker.remote_ip
        end.join(",")
      rescue
        'Unable to get worker ips'
      end

      def test_unit_processes
        self.workers.values.inject(0) do |sum,worker_data|
          sum += worker_data.worker_options[:test_unit_processes]
          sum
        end
      end

      def cucumber_processes
        self.workers.values.inject(0) do |sum,worker_data|
          sum += worker_data.worker_options[:cucumber_processes]
          sum
        end
      end

      def rspec_processes
        self.workers.values.inject(0) do |sum,worker_data|
          sum += worker_data.worker_options[:rspec_processes]
          sum
        end
      end
    end

    attr_accessor :client_type

    def receive_object(ruby_object)
      case ruby_object
      when BuildOutput
        send_to_requester(ruby_object)
      when BuildStatus
        puts "Received object #{ruby_object.inspect}"
        collect_status_response(ruby_object)
      when WorkerConnected
        self.workers[self.signature] = Borg::WorkerData.new(self,ruby_object.options)
        @client_type = :worker
      when BuildRequester
        puts "Got a build request here with data #{ruby_object.inspect}"
        self.requestors[self.signature] = self
        @client_type = :requestor
        check_for_workers && add_tests_to_redis && start_build(ruby_object)
      end
    end

    def check_for_workers
      return true unless workers.empty?
      send_error_to_requester("No worker found running")
      false
    end

    def send_error_to_requester(message)
      send_to_requester(BuildOutput.new(message))
      send_to_requester(BuildStatus.new(1))
    end

    def add_tests_to_redis
      begin
        puts "Total number of workers are #{workers.size} and their ips are #{Borg::Server.worker_ips}"
        TestUnit.new().add_to_redis(Server.test_unit_processes)
        CucumberRunner.new().add_to_redis(Server.cucumber_processes)
        true
      rescue
        puts $!.message
        puts $!.backtrace
        send_error_to_requester("Error adding files to redis")
        false
      end
    end

    def collect_status_response(ruby_object)
      self.status_reports << ruby_object
      self.status_count -= 1
      puts "Status count is #{self.status_count} and received from worker #{remote_ip} with status #{ruby_object.exit_status}"
      if(status_count <= 0)
        error_status = status_reports.any? {|x| x.exit_status != 0 }
        self.status_reports = []
        self.status_count = 0
        if(error_status)
          send_to_requester(BuildStatus.new(1))
        else
          send_to_requester(BuildStatus.new(0))
        end
      end
    end

    def unbind
      workers.delete(self.signature)
      requestors.delete(self.signature)
      if(client_type == :requestor)
        self.status_count = 0
        self.status_reports = []
      end
    end

    def start_build(build_request)
      workers.each do |key,worker_data|
        self.status_count += 1
        worker_data.worker.send_object(StartBuild.new(build_request.sha))
      end
    end

    def send_to_requester(ruby_object)
      requestors.each do |key,requester|
        requester.send_object(ruby_object)
      end
    end

    def remote_ip
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      ip
    rescue
      'unable to get ip'
    end
  end
end
