require "spec_helper"
require "borg/borg_messages"

describe Borg do
  describe "Worker connected" do
    it "should accept options as well" do
      worker_connected = Borg::WorkerConnected.new('foo',
        :unit_process_count => 2,
        :cucumber_process_count => 3,
        :rspec_process_count => 2)
      worker_connected.options[:unit_process_count].should == 2
      worker_connected.options[:cucumber_process_count].should == 3
      worker_connected.options[:rspec_process_count].should == 2
    end
  end
end
