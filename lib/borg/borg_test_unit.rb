module Borg
  class TestUnit
    include AbstractAdapter

    def run(n = Borg::Config.test_unit_processes)
      puts Borg::Config.test_unit_processes
      redirect_stdout()
      puts n
      
      load_environment('test')
      remove_file_groups_from_redis('tests',n) do |index,test_files|
        prepare_databse(index) unless try_migration_first(index)
        test_files.split(',').each do |fl|
          load(Rails.root.to_s + fl)
        end
      end
    end

    def add_to_redis(worker_count)
      test_files = (Dir["#{Rails.root}/test/unit/**/**_test.rb"] + Dir["#{Rails.root}/test/functional/**/**_test.rb"]).map do |fl|
        fl.gsub(/#{Rails.root}/,'')
      end.sort.in_groups(worker_count, false)
      add_files_to_redis(test_files,'tests')
    end
  end
end
