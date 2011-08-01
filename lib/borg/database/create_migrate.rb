module Borg
  class Database::CreateMigrate

    # taken from rails shamelessly
    def create_database(config)
      begin
        if config['adapter'] =~ /sqlite/
          if File.exist?(config['database'])
            $stdout.puts "#{config['database']} already exists"
          else
            begin
              # Create the SQLite database
              ActiveRecord::Base.establish_connection(config)
              ActiveRecord::Base.connection
            rescue Exception => e
              $stdout.puts e, *(e.backtrace)
              $stdout.puts "Couldn't create database for #{config.inspect}"
            end
          end
          return # Skip the else clause of begin/rescue
        else
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection
        end
      rescue
        case config['adapter']
        when /mysql/
          if config['adapter'] =~ /jdbc/
            #FIXME After Jdbcmysql gives this class
            require 'active_record/railties/jdbcmysql_error'
            error_class = ArJdbcMySQL::Error
          else
            error_class = config['adapter'] =~ /mysql2/ ? Mysql2::Error : Mysql::Error
          end
          access_denied_error = 1045
          begin
            ActiveRecord::Base.establish_connection(config.merge('database' => nil))
            ActiveRecord::Base.connection.create_database(config['database'], mysql_creation_options(config))
            ActiveRecord::Base.establish_connection(config)
          rescue error_class => sqlerr
            if sqlerr.errno == access_denied_error
              print "#{sqlerr.error}. \nPlease provide the root password for your mysql installation\n>"
              root_password = $stdin.gets.strip
              grant_statement = "GRANT ALL PRIVILEGES ON #{config['database']}.* " \
              "TO '#{config['username']}'@'localhost' " \
              "IDENTIFIED BY '#{config['password']}' WITH GRANT OPTION;"
              ActiveRecord::Base.establish_connection(config.merge(
                                                             'database' => nil, 'username' => 'root', 'password' => root_password))
              ActiveRecord::Base.connection.create_database(config['database'], creation_options)
              ActiveRecord::Base.connection.execute grant_statement
              ActiveRecord::Base.establish_connection(config)
            else
              $stdout.puts sqlerr.error
              $stdout.puts "Couldn't create database for #{config.inspect}, charset: #{config['charset'] || @charset}, collation: #{config['collation'] || @collation}"
              $stdout.puts "(if you set the charset manually, make sure you have a matching collation)" if config['charset']
            end
          end
        when /postgresql/
          @encoding = config['encoding'] || ENV['CHARSET'] || 'utf8'
          begin
            ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
            ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
            ActiveRecord::Base.establish_connection(config)
          rescue Exception => e
            $stdout.puts e, *(e.backtrace)
            $stdout.puts "Couldn't create database for #{config.inspect}"
          end
        end
      else
        # Bug with 1.9.2 Calling return within begin still executes else
        $stdout.puts "#{config['database']} already exists" unless config['adapter'] =~ /sqlite/
      end
    end

    def try_migration_first(db_counter)
      begin
        db_config = get_connection_config(db_counter)
        ActiveRecord::Base.establish_connection(db_config)
        ActiveRecord::Base.connection()
        migrate_db()
        return true
      rescue Exception => e
        $stdout e.message
        return false
      end
    end

    def prepare_databse(db_counter)
      create_db_using_raw_sql(db_counter)
      try_migration_first(db_counter)
    end

    def create_db_using_raw_sql(db_counter)
      test_config = config['test']
      db_config = get_connection_config(db_counter)
      create_database(db_config)
    end

    def migrate_db
      ENV["VERBOSE"] = "true"
      Rake::Task["db:test:prepare"].invoke
    end

    def get_connection_config(db_counter)
      default_settings = config["test"].clone()
      default_settings['database'] = "#{default_settings['database']}_#{db_counter}"
      default_settings
    end

    def config
      ActiveRecord::Base.configurations
    end

  end
end
