require "spec_helper"
require "borg/borg_worker"

describe Borg::Worker do
  describe "Worker with server" do
    it "should send WorkerConnected message after connection to server is completed" do

    end
  end

  describe "Running the build" do
    it "should update the code before starting the build"
    it "should collect status reports for each process"
    it "should send status report based on each step of the build process"
  end
end
