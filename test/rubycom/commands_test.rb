require "#{File.dirname(__FILE__)}/../../lib/rubycom/commands.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class CommandsTest < Test::Unit::TestCase

  def test_get_top_level_commands
    test_command_list = [:test_command, :test_command_no_docs, :test_command_with_arg, :test_command_arg_named_arg,
                         :test_command_with_args, :test_command_with_options, :test_command_all_options,
                         :test_command_options_arr, :test_command_with_return, :test_command_arg_timestamp,
                         :test_command_arg_false, :test_command_arg_arr, :test_command_arg_hash,
                         :test_command_mixed_options]
    result_command_list = Rubycom::Commands.get_top_level_commands(UtilTestModule)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_top_level_commands_nil_base
    test_command_list = []
    result_command_list = Rubycom::Commands.get_top_level_commands(nil)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_commands_nil_base
    test_command_list = []
    result_command_list = Rubycom::Commands.get_commands(nil)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_top_level_commands_singleton_base
    test_command_list = []
    result_command_list = Rubycom::Commands.get_top_level_commands(UtilTestNoSingleton)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

end