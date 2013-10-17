require "#{File.dirname(__FILE__)}/../../lib/rubycom/sub_process_executor.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class SubProcessExecutorTest < Test::Unit::TestCase

  def test_execute_command
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_parameters = {:test_arg => "testing_argument", :test_option_int => 10}
    result = Rubycom::SubProcessExecutor.execute_command(test_command, test_parameters)

    expected_keys = [:in,:out,:err]
    assert_true((result.keys - expected_keys).size == 0, "result keys should contain be #{expected_keys}")
    result.each_value{|v|
      assert_equal(IO,v.class)
    }
  end

end
