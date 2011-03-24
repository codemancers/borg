require "spec_helper"
require "active_support/core_ext/array/grouping"
require "borg/borg_server"

describe Borg::Server do
  describe "Server's interaction with worker" do
    before(:all) do
      @borg_server = Borg::Server.new("bar")
    end
    it "should store worker signature when connected" do
      worker_connected = Borg::WorkerConnected.new("bar", :test_unit_processes => 2)
      @borg_server.receive_object(worker_connected)
      Borg::Server.workers.should_not be_empty
      Borg::Server.workers.keys.should include("bar")
    end
    it "should remove worker signature when disconnected" do
      @borg_server.unbind()
      Borg::Server.workers.should be_empty
    end

    it "should split files according to number of total worker processes available" do
      borg_worker1 = Borg::Server.new("worker1")
      borg_worker2 = Borg::Server.new("worker2")
      borg_worker3 = Borg::Server.new("worker3")

      [borg_worker1,borg_worker2,borg_worker3].each do |borg|
        borg.should_receive(:send_object).any_number_of_times
      end
      borg_worker1.receive_object(Borg::WorkerConnected.new("worker1",
        :test_unit_processes => 2,
        :cucumber_processes  => 1))

      borg_worker2.receive_object(Borg::WorkerConnected.new("worker2",
        :test_unit_processes => 1,
        :cucumber_processes  => 4))

      borg_worker3.receive_object(Borg::WorkerConnected.new("worker3",
        :test_unit_processes => 1,
        :cucumber_processes  => 1))

      Borg::Server.test_unit_processes.should == 4
      Borg::Server.cucumber_processes.should == 6
    end
    
    after(:each) do
      Borg::Server.workers = {}
      Borg::Server.status_count = 0
      Borg::Server.requestors = {}
      Borg::Server.status_reports = []
    end
  end
  
  describe "Server's interaction with build requestor" do
    before(:all) do
      @borg_server = Borg::Server.new("foo")
    end
    it "should return error if no worker is running" do
      @borg_server.should_receive(:send_object).any_number_of_times

      build_requestor = Borg::BuildRequester.new("baz")

      @borg_server.receive_object(build_requestor)

      Borg::Server.requestors.should_not be_empty
      Borg::Server.requestors.keys.should include("foo")
    end

    it "should add files to redis server before starting the build" do
      borg_worker = Borg::Server.new("worker_connection")
      worker_connected = Borg::WorkerConnected.new("bar", :test_unit_processes => 2)
      borg_worker.receive_object(worker_connected)

      Borg::Server.workers.should_not be_empty
      Borg::Server.workers.keys.should include("worker_connection")

      build_requestor = Borg::BuildRequester.new("baz")      
      
      @borg_server.should_receive(:add_tests_to_redis).and_return(true)
      borg_worker.should_receive(:send_object).any_number_of_times

      @borg_server.receive_object(build_requestor)
      Borg::Server.status_count.should == 1
    end

    it "should remove requestor when disconnected" do
      @borg_server.unbind

      Borg::Server.requestors.should be_empty
      Borg::Server.status_count.should == 0
    end
  end

  describe "Server collecting status reports" do
    before(:all) do
      Borg::Server.workers = {}
      @borg_server = Borg::Server.new("server")
      @borg_worker = Borg::Server.new("worker")
    end

    it "should collect status reports from workers" do
      Borg::Server.status_reports.should be_empty
      Borg::Server.status_count.should == 0
      Borg::Server.status_count = 2
      
      build_status1 = Borg::BuildStatus.new("foo")
      build_status2 = Borg::BuildStatus.new("bar")
      
      @borg_worker.receive_object(build_status1)
      Borg::Server.status_count.should == 1
      Borg::Server.status_reports.size.should == 1

      @borg_worker.receive_object(build_status2)
      Borg::Server.status_count.should == 0
      Borg::Server.status_reports.size.should == 0
    end

    it "should clear out status reports after requestor has disconnected" do
      build_requestor = Borg::BuildRequester.new("requestor")
      @borg_server.should_receive(:add_tests_to_redis).and_return("true")
      @borg_server.should_receive(:send_object).any_number_of_times

      worker_connection = Borg::WorkerConnected.new("worker_connection", :test_unit_processes => 2)
      @borg_worker.receive_object(worker_connection)
      @borg_worker.should_receive(:send_object).any_number_of_times
      
      build_status1 = Borg::BuildStatus.new("foo")
      build_status2 = Borg::BuildStatus.new("bar")
      
      Borg::Server.status_count = 2
      Borg::Server.status_reports = []

      @borg_worker.receive_object(build_status1)
      Borg::Server.status_count.should == 1
      Borg::Server.status_reports.size.should == 1

      @borg_server.receive_object(build_requestor)
      @borg_server.unbind
      Borg::Server.status_count.should == 0
      Borg::Server.status_reports.size.should == 0
    end
  end
end
