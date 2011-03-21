module Borg
  class Requestor < EM::Connection
    include EM::P::ObjectProtocol
    attr_accessor :server_running, :updated_at
    def self.make_request
      EM.connect(Borg::Config.ip,Borg::Config.port,Requestor)
    end

    def connection_completed
      @server_running = true
      @updated_at = Time.now
      send_object(BuildRequester.new(current_ref))
      EM.add_periodic_timer(1) { check_for_inactivity }
    end

    def check_for_inactivity
      time_diff = Time.now - @updated_at
      if(time_diff > Borg::Config.inactivity_timeout)
        puts "No response received from the server for a period of #{time_diff} seconds"
        abort("Error running tests because no response received from the server for #{time_diff} seconds")
      end
    end

    def current_ref
      Git.new().local_branch_ref
    end

    def receive_object(ruby_object)
      case ruby_object
      when BuildOutput
        @updated_at = Time.now
        print ruby_object.data
      when BuildStatus
        @updated_at = Time.now
        stop_build(ruby_object)
      end
    end

    def unbind
      unless @server_running
        puts "Error running server"
        EM.stop()
      else
        EM.stop()
      end
    end

    def stop_build(ruby_object)
      puts
      if(ruby_object.exit_status == 0)
        puts "Successfully ran all tests"
        EM.stop()
      else
        abort("Error running tests")
      end
    end
    
  end
end
