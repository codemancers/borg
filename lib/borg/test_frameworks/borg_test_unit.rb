module Borg
  class TestUnit
    include AbstractAdapter

    def run(n = 3)
      redirect_stdout()
      load_environment('test')
      remove_file_groups_from_redis('tests', n) do |index, test_files|
        prepare_databse(index) unless try_migration_first(index)
        test_files.split(',').each do |fl|
          load(Rails.root.to_s + fl)
        end
      end
    end

    def add_to_redis(worker_count)
      test_files = (Dir["#{Rails.root}/test/unit/**/**_test.rb"] + Dir["#{Rails.root}/test/functional/**/**_test.rb"]).map do |fl|
        fl.gsub(/#{Rails.root}/, '')
      end.sort.in_groups(worker_count, false)
      add_files_to_redis(test_files, 'tests')
    end

    def run_tests_locally(dir, n = 2)
      load_environment('test')
      dir = "#{Rails.root}/test/#{dir}/**/*_test.rb" unless dir.index(Rails.root.to_s)
      groups = Dir[dir].sort.in_groups(n, false)

      pids = fork_tests(groups)

      Signal.trap 'SIGINT', lambda { pids.each { |p| Process.kill("KILL", p) }; exit 1 }
      exit_statuses = Process.waitall.map { |pid, status| status.exitstatus }
      raise "Error running #{dir}" if (exit_statuses.any? { |x| x != 0 })
    end

    def fork_tests(groups)
      pids = []

      GC.start
      groups.each_with_index do |group, index|
        pids << Process.fork do
          # If already prepared, reconnect. Else prepare.
          prepare_databse(index) unless try_migration_first(index)
          group.each { |f| load(f) unless f =~ /^-/ }
        end
      end

      pids
    end

  end
end
