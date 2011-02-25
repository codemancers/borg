require "spec_helper"
require 'borg/test_unit_benchmark'


describe Test::Unit::UI::Console::TestRunner, "test unit benchmark" do
  before  do
    @test_directory = File.join(File.dirname(__FILE__), 'tests')
    @test_filename = "#{@test_directory}/foo_test.rb"
  end

  it "should record test run time of a file in redis" do
    system("ruby #{@test_filename}")
  end
end
