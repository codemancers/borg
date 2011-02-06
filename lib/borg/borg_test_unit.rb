module Borg
  class TestUnit
    include AbstractAdapter

    def run(n = 3)
      redirect_stdout()
      load_environment('test')
      all_status = []

      r = Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)

      redis_has_files = true

      loop do
        local_pids = []

        n.times do |index|
          test_files = r.rpop('tests')
          if(test_files)
            local_pids << Process.fork do
              prepare_databse(index) unless try_migration_first(index)
              test_files.split(',').each do |fl|
                load(Rails.root.to_s + fl)
              end
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

    # def run(size = 2)
    #   redirect_stdout()
    #   load_environment('test')
    #   pids = []
    #   size.times do |index|
    #     pids << Process.fork do
    #       prepare_databse(index) unless try_migration_first(index)
    #       r = Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)
    #       while (filename = r.rpop('tests'))
    #         unless filename =~ /^-/
    #           full_filename = Rails.root.to_s + filename
    #           load(full_filename) 
    #         end
    #       end
    #     end
    #   end
    #   Signal.trap 'SIGINT', lambda { pids.each { |p| Process.kill("KILL", p) }; exit 1 }

    #   errors = Process.waitall.map { |pid, status| status.exitstatus }
    #   raise "Error running test" if (errors.any? { |x| x != 0 })
    # end

    def add_to_redis(worker_count)
      test_files = (Dir["#{Rails.root}/test/unit/**/**_test.rb"] + Dir["#{Rails.root}/test/functional/**/**_test.rb"]).map do |fl|
        fl.gsub(/#{Rails.root}/,'')
      end.sort.in_groups(worker_count, false)

      redis = Redis.new(:host => Borg::Config.redis_ip,:port => Borg::Config.redis_port)
      redis.del 'tests'
      test_files.each { |x| redis.rpush('tests', x.join(",")) }
    end
  end
end
