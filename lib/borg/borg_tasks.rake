
namespace :borg do
  [:unit, :functional].each do |t|
    type = t.to_s.sub(/s$/, '')
    task_name = type + "_local"

    desc "Run #{type} tests locally"
    task task_name.to_sym, :count do |t, args|
      size = args[:count] ? args[:count].to_i : 3
      puts "Running #{type} tests using #{size} processes"
      Borg::TestUnit.new().run_tests_locally(type, size)
    end
  end
  
  desc "Request server to run test"
  task :build => :environment do
    EM.run {
      Borg::Requestor.make_request
    }
  end

  desc "Start server"
  task :start_server => :environment do
    borg_daemon = Borg::Daemon.new("borg_server")
    borg_daemon.start do
      EM.run {
        puts "Ip is #{Borg::Config.ip} and #{Borg::Config.port}"
        EM.start_server(Borg::Config.ip,Borg::Config.port,Borg::Server)
      }
    end
  end

  desc "Start Client"
  task :start_client => :environment do
    borg_daemon = Borg::Daemon.new("borg_worker")
    borg_daemon.start do
      EM.run {
        EM.connect(Borg::Config.ip,Borg::Config.port,Borg::Worker)
      }
    end
  end

  desc "Stop Client"
  task :stop_client => :environment do
    borg_daemon = Borg::Daemon.new("borg_worker")
    borg_daemon.stop
  end

  desc "Stop Server"
  task :stop_server => :environment do
    borg_daemon = Borg::Daemon.new("borg_server")
    borg_daemon.stop
  end

  desc "Run unit and functional test"
  task :test => :environment do
   Borg::TestUnit.new().run(Borg::Config.test_unit_processes)
  end

  desc "Run cucumber tests"
  task :cucumber => :environment do
    Borg::CucumberRunner.new().run(Borg::Config.cucumber_processes)
  end
end
