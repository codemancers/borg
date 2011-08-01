module Borg
  module AbstractAdapter
    def load_environment(env_name)
      puts "Loading Rails.."
      ENV["RAILS_ENV"] = env_name
      puts "Setting rails environment to #{env_name}"
      Rails.env = env_name
      require(File.join(Rails.root, 'config', 'environment'))
      $: << "#{Rails.root}/test"
      $: << "#{Rails.root}/test/test_helpers"
      require File.join(Rails.root, "test", "test_helper")
    end

    # Free file descriptors and
    # point them somewhere sensible
    # STDOUT/STDERR should go to a logfile
    def redirect_io(logfile_name)
      begin
        ; STDIN.reopen "/dev/null";
      rescue ::Exception;
      end

      if logfile_name
        begin
          STDOUT.reopen logfile_name, "a"
          STDOUT.sync = true
        rescue ::Exception
          begin
            ; STDOUT.reopen "/dev/null";
          rescue ::Exception;
          end
        end
      else
        begin
          ; STDOUT.reopen "/dev/null";
        rescue ::Exception;
        end
      end

      begin
        ; STDERR.reopen STDOUT;
      rescue ::Exception;
      end
      STDERR.sync = true
    end

    def redirect_stdout
      STDOUT.sync = true
      begin
        STDERR.reopen STDOUT;
      rescue ::Exception;
      end
      STDERR.sync = true
    end


    def redis
      Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)
    end

    def add_files_to_redis(files,key)
      redis.del key
      files.each { |x| redis.rpush(key, x.join(",")) }
    end

    def remove_file_groups_from_redis(key,process_count,&block)
      redis_has_files = true
      @redis_connection = redis
      all_status = []

      loop do
        local_pids = []
        process_count.times do |index|
          test_files = @redis_connection.rpop(key)
          if(test_files)
            local_pids << Process.fork { block.call(index,test_files) }
          else
            redis_has_files = false
            break
          end
        end

        Signal.trap 'SIGINT', lambda { local_pids.each { |p| Process.kill("KILL", p) }; exit 1 }
        all_status += Process.waitall.map { |pid, status| status.exitstatus }
        break unless redis_has_files
      end #end of loop

      raise "Error running #{key} tests" if (all_status.any? { |x| x != 0 })
    end #end of method remove_file_groups_from_redis

  end
end
