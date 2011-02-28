require 'test/unit'
require 'test/unit/testresult'
require 'test/unit/testcase'
require 'test/unit/ui/console/testrunner'

class Test::Unit::UI::Console::TestRunner
  alias attach_to_mediator_old attach_to_mediator

  def attach_to_mediator
    attach_to_mediator_old
    @mediator.add_listener(Test::Unit::TestSuite::STARTED, &method(:test_suite_started))
    @mediator.add_listener(Test::Unit::TestSuite::FINISHED, &method(:test_suite_finished))
  end

  alias test_started_old test_started
  def test_started(name)
    test_started_old(name)
    puts "Name is #{name} and file is #{__FILE__}"
  end


  def test_suite_started(suite_name)
    @suite_benchmarks[suite_name] = Time.now
  end

  def test_suite_finished(suite_name)
    puts "Suite is #{@suite.name}"
    time_taken = Time.now - @suite_benchmarks[suite_name]
    puts "Time taken is for #{suite_name} is #{time_taken}"
  end

end
