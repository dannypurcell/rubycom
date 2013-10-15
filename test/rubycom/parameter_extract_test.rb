require "#{File.dirname(__FILE__)}/../../lib/rubycom/parameter_extract.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class ParameterExtractTest < Test::Unit::TestCase

  def test_extract_parameters
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10}}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line)
    expected = {:test_arg => "testing_argument", :test_option_int => 10}
    assert_equal(expected, result)
  end

  def test_extract_parameters_help_opt
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10, "help" => true}}
    result = nil
    assert_raise(Rubycom::RubycomError) { result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_extract_parameters_help_flag
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10}, :flags => {"h" => true}}
    result = nil
    assert_raise(Rubycom::RubycomError) { result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_extract_parameters_unknown_opts
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10, "extraneous_opt" => true}}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line)
    expected = {:test_arg => "testing_argument", :test_option_int => 10}
    assert_equal(expected, result)
  end

  def test_extract_parameters_unknown_flags
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10}, :flags => {"z" => true}}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line)
    expected = {:test_arg => "testing_argument", :test_option_int => 10}
    assert_equal(expected, result)
  end

end
