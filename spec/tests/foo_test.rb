require "test/unit"

class FooTest < Test::Unit::TestCase
  def setup
    @name = "The borg is coming"
  end

  def test_name
    assert_match /borg/, @name
  end
end
