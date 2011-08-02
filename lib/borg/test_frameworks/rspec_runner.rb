module Borg
  class RSpecRunner
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
      test_files = (Dir["#{Rails.root}/**/*_spec.rb"]).map do |fl|
        fl.gsub(/#{Rails.root}/, '')
      end.sort.in_groups(worker_count, false)
      add_files_to_redis(test_files, 'tests')
    end

  end
end
