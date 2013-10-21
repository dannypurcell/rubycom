require "#{File.dirname(__FILE__)}/../../lib/rubycom/executor.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class ExecutorTest < Test::Unit::TestCase

  def capture_out(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  def test_execute_command
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_parameters = {:test_arg => "testing_argument", :test_option_int => 10}
    result = Rubycom::Executor.execute_command(test_command, test_parameters)
    expected = ["testing_argument", 10]
    assert_equal(expected, result)
  end

  def test_execute_command_no_args
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_parameters = {}
    result = nil
    assert_raise(Rubycom::RubycomError) { result = Rubycom::Executor.execute_command(test_command, test_parameters) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_execute_command_none_required
    test_command = UtilTestModule.public_method(:test_command)
    test_parameters = {}
    result = capture_out { Rubycom::Executor.execute_command(test_command, test_parameters) }
    expected = "command test\n"
    assert_equal(expected, result)
  end

  def test_execute_command_missing_missing_arg
    test_command = UtilTestModule.public_method(:test_command_with_options)
    test_parameters = {:test_option => 'testing_opt'}
    result = nil
    assert_raise(Rubycom::RubycomError) { result = Rubycom::Executor.execute_command(test_command, test_parameters) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_execute_command_too_many_args
    test_command = UtilTestModule.public_method(:test_command_with_options)
    test_parameters = {:test_arg => "testing_argument", :test_option => 'testing_opt', :test_extra_opt => 'extra'}
    result = capture_out { Rubycom::Executor.execute_command(test_command, test_parameters) }
    expected = "test_arg=testing_argument,test_option=testing_opt\n"
    assert_equal(expected, result)
  end

  def test_execute_all_opt_override_first
    test_command = UtilTestModule.public_method(:test_command_all_options)
    test_parameters = {:test_arg => "test_arg_modified"}
    result = capture_out { Rubycom::Executor.execute_command(test_command, test_parameters) }
    expected = "Output is test_arg=test_arg_modified,test_option=test_option_default\n"
    assert_equal(expected, result)
  end

  def test_execute_all_opt_override_second
    test_command = UtilTestModule.public_method(:test_command_all_options)
    test_parameters = {:test_option => "test_opt_modified"}
    result = capture_out { Rubycom::Executor.execute_command(test_command, test_parameters) }
    expected = "Output is test_arg=test_arg_default,test_option=test_opt_modified\n"
    assert_equal(expected, result)
  end

end
