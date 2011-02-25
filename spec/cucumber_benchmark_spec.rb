require "spec_helper"
require "cucumber"
require "borg/cucumber_benchmark"

describe Borg::CucumberBenchmark, "cucumber benchmark" do
  include Helpers

  before do
    @feature_folder = File.join(File.dirname(__FILE__),'features')
    @feature_filename = "#{@feature_folder}/foo.feature"
    @args = %w(--format Borg::CucumberBenchmark) + Array(@feature_filename)
  end

  it "should record benchmark of cucumber features files" do
    failure = Cucumber::Cli::Main.execute(@args)
    redis[@feature_filename].should_not be_nil
  end

  after do
    redis.del(@feature_filename)
  end
end
