module Borg
  class CucumberRunner
    include AbstractAdapter
    attr_accessor :file_splits
    def run(n = 1)
      redirect_stdout()
      load_environment('cucumber')
      require File.join(File.dirname(__FILE__),"cucumber_benchmark")
      remove_file_groups_from_redis('cucumber',n) do |index,feature_files|
        prepare_databse(index) unless try_migration_first(index)
        full_feature_path = feature_files.split(',').map do |fl|
          Rails.root.to_s + fl
        end
        args = %w(--format Borg::CucumberBenchmark) + full_feature_path
        failure = Cucumber::Cli::Main.execute(args)
        raise "Cucumber failed" if failure
      end
    end

    def feature_running_time(filename)
      (redis[filename] || 240).to_i
    end

    def add_to_redis(worker_count)
      file_splitter = FileSplitter.new(worker_count)
      Dir["#{Rails.root}/features/**/*.feature"].each do |fl|
        filename = fl.gsub(/#{Rails.root}/,'')
        file_splitter.history << RunHistory.new(filename,feature_running_time(filename))
      end
      @file_splits = file_splitter.split()
      feature_files = file_splits.map do |files|
        files.map(&:filename)
      end
      add_files_to_redis(feature_files,'cucumber')
    end
  end
end
