require "spec_helper"
require 'borg/test_unit_benchmark'


describe Test::Unit::UI::Console::TestRunner, "test unit benchmark" do
  before  do
    @test_directory = File.join(File.dirname(__FILE__), 'tests')
    @test_files = Dir["#{@test_directory}/*.rb"]
  end

  it "should record test run time of a file in redis" do
    pid = Process.fork do
      @test_files.each do |file|
        load file
      end
    end
    Process.waitall
  end
end
