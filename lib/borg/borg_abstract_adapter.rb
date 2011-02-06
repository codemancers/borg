module Borg
  module AbstractAdapter
    def load_environment(env_name)
      puts "Loading Rails.."
      ENV["RAILS_ENV"] = env_name
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

    def try_migration_first(db_counter)
      begin
        db_config = get_connection_config(db_counter)
        ActiveRecord::Base.establish_connection(db_config)
        ActiveRecord::Base.connection()
        migrate_db()
        return true
      rescue Exception => e
        puts e.message
        return false
      rescue StandardError
        puts $!.message
        return false
      rescue Mysql2::Error
        puts $!.message
        return false
      end
    end

    def prepare_databse(db_counter)
      create_db_using_raw_sql(db_counter)
      try_migration_first(db_counter)
    end

    def create_db_using_raw_sql(db_counter)
      test_config = config['test']
      sql_connection = Mysql2::Client.new(test_config.symbolize_keys)
      db_config = get_connection_config(db_counter)
      sql_connection.query("DROP DATABASE IF EXISTS #{db_config['database']}")
      sql_connection.query("CREATE DATABASE #{db_config['database']}")
      sql_connection.close()
    end

    def migrate_db
      ENV["VERBOSE"] = "true"
      Rake::Task["db:migrate"].invoke
    end

    def get_connection_config(db_counter)
      default_settings = config["test"].clone()
      default_settings['database'] = "#{default_settings['database']}_#{db_counter}"
      default_settings
    end

    def config
      ActiveRecord::Base.configurations
    end

    def redis
      Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)
    end

    def add_files_to_redis(files,key)
      redis.del key
      files.each { |x| redis.rpush(key, x.join(",")) }
    end

    def remove_file_groups_from_redis(key,&block)
      redis_has_files = true
      @redis_connection = redis
      all_status = []

      loop do
        local_pids = []
        n.times do |index|
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
