require "spec_helper"
require "borg/borg_requestor"

describe Borg::Requestor do
  describe "Inactivity timeout" do

    it "should close the connection after some inactivity time" do
      class << EM
        def add_periodic_timer(time); end
      end
      Borg::Config.inactivity_timeout = 5
      @borg_requestor = Borg::Requestor.new("foo")

      @borg_requestor.should_receive(:current_ref).and_return("foo")
      @borg_requestor.should_receive(:send_object)
      @borg_requestor.should_receive(:abort)
      @borg_requestor.connection_completed()

      @borg_requestor.server_running.should_not be_nil
      @borg_requestor.updated_at.should_not be_nil
      sleep(6)
      @borg_requestor.check_for_inactivity
    end
  end
end