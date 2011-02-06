module Borg
  class CucumberRunner
    include AbstractAdapter
    def run(n = 3)
      redirect_stdout()
      load_environment('cucumber')
      all_status = []

      r = Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)

      redis_has_files = true

      loop do
        local_pids = []
        
        n.times do |index|
          feature_files = r.rpop('cucumber')
          if(feature_files)
            local_pids << Process.fork do
              prepare_databse(index) unless try_migration_first(index)
              full_feature_path = feature_files.split(',').map do |fl|
                Rails.root.to_s + fl
              end
              args = %w(--format progress) + full_feature_path
              failure = Cucumber::Cli::Main.execute(args)
              raise "Cucumber failed" if failure
            end
          else
            redis_has_files = false
            break
          end
        end #end of n#times

        Signal.trap 'SIGINT', lambda { local_pids.each { |p| Process.kill("KILL", p) }; exit 1 }
        
        all_status += Process.waitall.map { |pid, status| status.exitstatus }
        
        break unless redis_has_files
      end # end of loop
      
      raise "Error running cucumber tests" if (all_status.any? { |x| x != 0 })
    end

    def feature_files(files)
      make_command_line_safe(FileList[ files || [] ])
    end

    def make_command_line_safe(list)
      list.map{|string| string.gsub(' ', '\ ')}
    end

    def add_to_redis(worker_count)
      feature_files = Dir["#{Rails.root}/features/**/*.feature"].map do |fl|
        fl.gsub(/#{Rails.root}/,'')
      end.sort.in_groups(worker_count, false)

      redis = Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)
      redis.del 'cucumber'
      feature_files.each { |x| redis.rpush('cucumber', x.join(',')) }
    end
    
  end
end
