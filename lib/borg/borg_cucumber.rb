module Borg
  class CucumberRunner
    include AbstractAdapter

    def run(n = Borg::Config.cucumber_processes)
      puts Borg::Config.cucumber_processes
      redirect_stdout()
      load_environment('cucumber')
      puts n;
      remove_file_groups_from_redis('cucumber',n) do |index,feature_files|
        prepare_databse(index) unless try_migration_first(index)
        full_feature_path = feature_files.split(',').map do |fl|
          Rails.root.to_s + fl
        end
        args = %w(--format progress) + full_feature_path
        failure = Cucumber::Cli::Main.execute(args)
        raise "Cucumber failed" if failure
      end

    end

    def add_to_redis(worker_count)
      feature_files = Dir["#{Rails.root}/features/**/*.feature"].map do |fl|
        fl.gsub(/#{Rails.root}/,'')
      end.sort.in_groups(worker_count, false)
      add_files_to_redis(feature_files,'cucumber')
    end
  end
end
