require "spec_helper"

describe Borg::Config do
  it "should return stuff from yml file" do
    Borg::Config.ip.should == 'localhost'
    Borg::Config.port.should == 10001
    Borg::Config.inactivity_timeout.should == 200
  end
end
