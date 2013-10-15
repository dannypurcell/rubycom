require "#{File.dirname(__FILE__)}/../../lib/rubycom/executor.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class ExecutorTest < Test::Unit::TestCase

  def test_execute_command
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_parameters = {:test_arg => "testing_argument", :test_option_int => 10}
    result = Rubycom::Executor.execute_command(test_command, test_parameters)
    expected = ["testing_argument", 10]
    assert_equal(expected, result)
  end

end
