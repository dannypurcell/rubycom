require "#{File.dirname(__FILE__)}/../../lib/rubycom/documentation.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class DocumentationTest < Test::Unit::TestCase

  def test_get_doc
    method = UtilTestModule.public_method(:test_command_with_return)
    result_hash = Rubycom::Documentation.get_doc(method)
    assert_equal('A test_command with a return argument'.gsub(/\n|\r|\s/, ''), result_hash[:desc].join("\n").gsub(/\n|\r|\s/, ''))
    assert_equal(2, result_hash[:param].size)
    assert_equal('[String] test_arg a test argument'.gsub(/\n|\r|\s/, ''), result_hash[:param][0].gsub(/\n|\r|\s/, ''))
    assert_equal('[Integer] test_option_int an optional test argument which happens to be an Integer'.gsub(/\n|\r|\s/, ''), result_hash[:param][1].gsub(/\n|\r|\s/, ''))
    assert_equal(2, result_hash[:return].size)
    assert_equal('[Array] an array including both params if test_option_int != 1'.gsub(/\n|\r|\s/, ''), result_hash[:return][0].gsub(/\n|\r|\s/, ''))
    assert_equal('[String] a the first param if test_option_int == 1'.gsub(/\n|\r|\s/, ''), result_hash[:return][1].gsub(/\n|\r|\s/, ''))
  end

  def test_get_command_usage
    base = UtilTestModule
    command_name = 'test_command_arg_false'
    result = Rubycom::Documentation.get_command_usage(base, command_name)
    expected = <<-END.gsub(/^ {4}/, '')
    Usage: test_command_arg_false [-test_flag=false]
    Parameters:
        [Boolean] test_flag a test Boolean argument
    Returns:
        [Boolean] the flag passed in
    END
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_command_usage_nil_base
    base = nil
    command_name = 'test_command'
    assert_raise(Rubycom::CLIError) { Rubycom::Documentation.get_command_usage(base, command_name) }
  end

  def test_get_command_usage_nil_command
    base = UtilTestModule
    command_name = nil
    result = Rubycom::Documentation.get_command_usage(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_usage_no_command
    base = UtilTestModule
    command_name = ''
    result = Rubycom::Documentation.get_command_usage(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_usage_bad_base
    base = ":asd"
    command_name = 'test_command_with_options'
    assert_raise(Rubycom::CLIError) { Rubycom::Documentation.get_command_usage(base, command_name) }
  end

  def test_get_command_usage_invalid_command
    base = UtilTestModule
    command_name = '123asd!@#'
    assert_raise(Rubycom::CLIError) { Rubycom::Documentation.get_command_usage(base, command_name) }
  end

  def test_get_command_summary
    base = UtilTestModule
    command_name = 'test_command_with_options'
    expected = "test_command_with_options - A test_command with an optional argument\n"
    result = Rubycom::Documentation.get_command_summary(base, command_name)
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_command_summary_no_command
    base = UtilTestModule
    command_name = ''
    result = Rubycom::Documentation.get_command_summary(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_summary_nil_base
    base = nil
    command_name = 'test_command_with_options'
    assert_raise(Rubycom::CLIError) { Rubycom::Documentation.get_command_summary(base, command_name) }
  end

  def test_get_command_summary_nil_command
    base = UtilTestModule
    command_name = nil
    result = Rubycom::Documentation.get_command_summary(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_summary_wrong_base
    base = UtilTestNoSingleton
    command_name = 'test_command_with_options'
    assert_raise(Rubycom::CLIError) { Rubycom::Documentation.get_command_summary(base, command_name) }
  end

  def test_get_command_summary_bad_command
    base = UtilTestModule
    command_name = '!_fail_command_'
    assert_raise(Rubycom::CLIError) { Rubycom::Documentation.get_command_summary(base, command_name) }
  end

  def test_get_usage
    base = UtilTestModule
    result = Rubycom::Documentation.get_usage(base)
    expected = <<-END.gsub(/^ {4}/, '')
    Usage:
      UtilTestModule <command> [args]

    Commands:
    test_command                -  A basic test command
    test_command_no_docs
    test_command_with_arg       -  A test_command with one arg
    test_command_arg_named_arg  -  A test_command with an arg named arg
    test_command_with_args      -  A test_command with two args
    test_command_with_options   -  A test_command with an optional argument
    test_command_all_options    -  A test_command with all optional arguments
    test_command_options_arr    -  A test_command with an options array
    test_command_with_return    -  A test_command with a return argument
    test_command_arg_timestamp  -  A test_command with a Timestamp argument and an unnecessarily
                                   long description which should overflow when
                                   it tries to line up with other descriptions.
    test_command_arg_false      -  A test_command with a Boolean argument
    test_command_arg_arr        -  A test_command with an array argument
    test_command_arg_hash       -  A test_command with an Hash argument
    test_command_mixed_options  -  A test_command with several mixed options

    END
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_usage_nil_base
    base = nil
    result = Rubycom::Documentation.get_usage(base)
    assert_equal('', result)
  end

  def test_get_usage_no_singleton_base
    base = UtilTestNoSingleton
    result = Rubycom::Documentation.get_usage(base)
    assert_equal('', result)
  end

  def test_get_summary
    base = UtilTestModule
    result = Rubycom::Documentation.get_summary(base)
    expected = <<-END.gsub(/^ {4}/, '')
    Commands:
    test_command                -  A basic test command
    test_command_no_docs
    test_command_with_arg       -  A test_command with one arg
    test_command_arg_named_arg  -  A test_command with an arg named arg
    test_command_with_args      -  A test_command with two args
    test_command_with_options   -  A test_command with an optional argument
    test_command_all_options    -  A test_command with all optional arguments
    test_command_options_arr    -  A test_command with an options array
    test_command_with_return    -  A test_command with a return argument
    test_command_arg_timestamp  -  A test_command with a Timestamp argument and an unnecessarily
                                   long description which should overflow when
                                   it tries to line up with other descriptions.
    test_command_arg_false      -  A test_command with a Boolean argument
    test_command_arg_arr        -  A test_command with an array argument
    test_command_arg_hash       -  A test_command with an Hash argument
    test_command_mixed_options  -  A test_command with several mixed options
    END
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_summary_nil_base
    base = nil
    result = Rubycom::Documentation.get_summary(base)
    assert_equal('No Commands found for .', result)
  end

  def test_get_summary_no_singleton_base
    base = UtilTestNoSingleton
    result = Rubycom::Documentation.get_summary(base)
    assert_equal('No Commands found for UtilTestNoSingleton.', result)
  end
end