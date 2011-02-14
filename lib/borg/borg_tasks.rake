
namespace :borg do
  [:unit, :functional].each do |t|
    type = t.to_s.sub(/s$/, '')

    desc "Run #{type} tests"
    task t, :count do |t, args|
      Borg.load_environment
      size = args[:count] ? args[:count].to_i : 3
      #Borg.prepare_all_databases(size)
      puts "Running #{type} tests using #{size} processes"
      Borg.run_tests type, size
    end
  end
  
  desc "Request server to run test"
  task :build => :environment do
    # Borg::TestUnit.new().add_to_redis
    # Borg::CucumberRunner.new().add_to_redis
    EM.run {
      Borg::Requestor.make_request
    }
  end

  desc "Start server"
  task :start_server => :environment do
    EM.run {
      puts "Ip is #{Borg::Config.ip} and #{Borg::Config.port}"
      EM.start_server(Borg::Config.ip,Borg::Config.port,Borg::Server)
    }
  end

  desc "Start Client"
  task :start_client => :environment do
    EM.run {
      EM.connect(Borg::Config.ip,Borg::Config.port,Borg::Worker)
    }
  end

  desc "Run unit and functional test"
  task :test => :environment do
   Borg::TestUnit.new().run(Borg::Config.test_unit_processes)
  end

  desc "Run cucumber tests"
  task :cucumber => :environment do
    Borg::CucumberRunner.new().run(Borg::Config.cucumber_processes)
  end

  
#  desc "Run redis tests"
#  task :redis_test, :count do |t,args|
#    Borg.load_environment('test')
#    size = args[:count] ? args[:count].to_i : 3
#    puts "Running tests using #{size} processes"
#    Borg.run_redis_test(size)
#  end
#
#  desc "Run cucumber parallel test"
#  task :cucumber, :count do |t,args|
#    Borg.load_environment('cucumber')
#    size = args[:count] ? args[:count].to_i : 3
#    puts "Running Cucumber tests using #{size} processes"
#    puts "Using the default profile..."
#    Borg.run_cucumber(size)
#  end
end
