module Borg
  class Requestor < EM::Connection
    include EM::P::ObjectProtocol
    def self.make_request
      EM.connect(Borg::Config.ip,Borg::Config.port,Requestor)
    end

    def connection_completed
      @server_running = true
      current_ref = Git.new().local_branch_ref
      send_object(BuildRequester.new(current_ref))
    end

    def receive_object(ruby_object)
      case ruby_object
      when BuildOutput
        print ruby_object.data
      when BuildStatus
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
