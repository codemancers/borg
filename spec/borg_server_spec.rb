require "spec_helper"
require "borg/borg_server"

describe Borg::Server do
  describe "Server's interaction with worker" do
    before(:all) do
      @borg_server = Borg::Server.new("bar")
    end
    it "should store worker signature when connected" do
      worker_connected = Borg::WorkerConnected.new("bar")
      @borg_server.receive_object(worker_connected)
      Borg::Server.workers.should_not be_empty
      Borg::Server.workers.keys.should include("bar")
    end
    it "should remove worker signature when disconnected" do
      @borg_server.unbind()
      Borg::Server.workers.should be_empty
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
      worker_connected = Borg::WorkerConnected.new("bar")
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
end
