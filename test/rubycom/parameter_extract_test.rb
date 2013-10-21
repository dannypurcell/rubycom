require "#{File.dirname(__FILE__)}/../../lib/rubycom/parameter_extract.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class ParameterExtractTest < Test::Unit::TestCase

  def test_extract_parameters
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_doc = {
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10}}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc)
    test_command.parameters.each{|_, sym|
      assert_true(result.has_key?(sym), 'extracted parameters should include values for each method parameter')
    }
    assert_equal('testing_argument', result[:test_arg])
    assert_equal(10, result[:test_option_int])
  end

  def test_extract_parameters_help_opt
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_doc = {
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10, "help" => true}}
    result = nil
    assert_raise(Rubycom::RubycomError) { result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_extract_parameters_help_flag
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_doc = {
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10}, :flags => {"h" => true}}
    result = nil
    assert_raise(Rubycom::RubycomError) { result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_extract_parameters_unknown_opts
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_doc = {
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10, "extraneous_opt" => true}}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc)
    test_command.parameters.each{|_, sym|
      assert_true(result.has_key?(sym), 'extracted parameters should include values for each method parameter')
    }
    assert_equal('testing_argument', result[:test_arg])
    assert_equal(10, result[:test_option_int])
  end

  def test_extract_parameters_unknown_flags
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_doc = {
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10}, :flags => {"z" => true}}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc)
    test_command.parameters.each{|_, sym|
      assert_true(result.has_key?(sym), 'extracted parameters should include values for each method parameter')
    }
    assert_equal('testing_argument', result[:test_arg])
    assert_equal(10, result[:test_option_int])
  end

  def test_extract_parameters_default
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_doc = {
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"]}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc)
    test_command.parameters.each{|_, sym|
      assert_true(result.has_key?(sym), 'extracted parameters should include values for each method parameter')
    }
    assert_equal('testing_argument', result[:test_arg])
    assert_equal(1, result[:test_option_int])
  end

  def test_extract_parameters_arr
    test_command = UtilTestModule.public_method(:test_command_options_arr)
    test_command_doc = {
        :parameters => [
            {:default => 'test_option_default', :doc => "an optional test argument", :doc_type => "String", :param_name => "test_option", :type => :opt},
            {:default => nil, :doc => "an optional array of arguments", :doc_type => "Array", :param_name => "test_options", :type => :rest}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_options_arr", 'test_option1', 'test_option2', 1.0, false]}
    result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc)
    test_command.parameters.each{|_, sym|
      assert_true(result.has_key?(sym), 'extracted parameters should include values for each method parameter')
    }
    assert_equal('test_option1', result[:test_option])
    assert_equal(['test_option2', 1.0, false], result[:test_options])
  end

  def test_extract_parameters_missing_required
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_command_doc = {
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ]
    }
    test_command_line = {:args => ["UtilTestModule", "test_command_with_return"], :opts => {"test_option_int" => 10}}
    result = nil
    assert_raise(Rubycom::RubycomError) { result = Rubycom::ParameterExtract.extract_parameters(test_command, test_command_line, test_command_doc) }
    expected = nil
    assert_equal(expected, result)
  end

end
