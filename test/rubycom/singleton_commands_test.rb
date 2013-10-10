require "#{File.dirname(__FILE__)}/../../lib/rubycom/singleton_commands.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class SingletonCommandsTest < Test::Unit::TestCase

  def test_get_command_constant_args_in
    test_mod = UtilTestComposite
    test_args = ['UtilTestModule', 'test_command', 'test_extra_arg']
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite,
        UtilTestModule,
        UtilTestModule.public_method(:test_command),
        "test_extra_arg"
    ]
    assert_equal(expected, result)
  end

  def test_get_command_constant_hash_in
    test_mod = UtilTestComposite
    test_args = {:command_line => {:args => ['UtilTestModule', 'test_command', 'test_extra_arg']}}
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite,
        UtilTestModule,
        UtilTestModule.public_method(:test_command),
        "test_extra_arg"
    ]
    assert_equal(expected, result)
  end

  def test_get_top_level_commands
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.get_top_level_commands(test_mod)
    expected = {:UtilTestComposite =>
                    {:UtilTestModule => :module,
                     :UtilTestNoSingleton => :module,
                     :test_composite_command => :method}}
    assert_equal(expected, result)
  end

  def test_get_commands
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.get_commands(test_mod)
    expected = {:UtilTestComposite =>
                    {:UtilTestModule =>
                         {:test_command => :method,
                          :test_command_all_options => :method,
                          :test_command_arg_arr => :method,
                          :test_command_arg_false => :method,
                          :test_command_arg_hash => :method,
                          :test_command_arg_named_arg => :method,
                          :test_command_arg_timestamp => :method,
                          :test_command_mixed_options => :method,
                          :test_command_no_docs => :method,
                          :test_command_options_arr => :method,
                          :test_command_with_arg => :method,
                          :test_command_with_args => :method,
                          :test_command_with_options => :method,
                          :test_command_with_return => :method},
                     :UtilTestNoSingleton => {},
                     :test_composite_command => :method}}
    assert_equal(expected, result)
  end

  def test_get_commands_all_false
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.get_commands(test_mod, false)
    expected = {:UtilTestComposite =>
                    {:UtilTestModule => :module,
                     :UtilTestNoSingleton => :module,
                     :test_composite_command => :method}}
    assert_equal(expected, result)
  end

end
