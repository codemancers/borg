require "spec_helper"
require "cucumber"
require "borg/cucumber_benchmark"
require "borg/borg_cucumber"

describe Borg::CucumberRunner do
  include Helpers
  
  describe "Splitting the cucumber files based on their historic running time" do
    before do
      @feature_folder = File.join(Rails.root,'features')
      @features = Dir["#{@feature_folder}/*.feature"]
      @args = %w(--format Borg::CucumberBenchmark) + @features
      @cuke_runner = Borg::CucumberRunner.new()
    end
    it "should split the files based on historic running times" do
      failure = Cucumber::Cli::Main.execute(@args)
      puts Rails.root
    end
  end
end
