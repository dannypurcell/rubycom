require "#{File.dirname(__FILE__)}/../../lib/rubycom/singleton_commands.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class SingletonCommandsTest < Test::Unit::TestCase

  def test_discover_command_command_run
    test_mod = UtilTestComposite
    test_args = {:args=>["UtilTestModule", "test_command_with_return", "testing_argument"],:opts=>{"test_option_int"=>10}}
    result = Rubycom::SingletonCommands.discover_command(test_mod, test_args)
    expected = UtilTestModule.public_method(:test_command_with_return)
    assert_equal(expected, result)
  end

  def test_discover_commands_nil
    test_mod = UtilTestComposite
    test_args = nil
    result = nil
    assert_raise(ArgumentError) { Rubycom::SingletonCommands.discover_commands(test_mod, test_args) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_discover_commands_nil_args
    test_mod = UtilTestComposite
    test_args = {}
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite
    ]
    assert_equal(expected, result)
  end

  def test_discover_commands_empty
    test_mod = UtilTestComposite
    test_args = {:args => []}
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite
    ]
    assert_equal(expected, result)
  end

  def test_discover_commands_command_before_module
    test_mod = UtilTestComposite
    test_args = {:args => ['test_command', 'UtilTestModule', 'test_extra_arg']}
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite,
        "test_command",
        "UtilTestModule",
        "test_extra_arg"
    ]
    assert_equal(expected, result)
  end

  def test_discover_commands_no_module_match
    test_mod = UtilTestComposite
    test_args = {:args => ['test_arg', 'test_command', 'test_extra_arg']}
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite,
        "test_arg",
        "test_command",
        "test_extra_arg"
    ]
    assert_equal(expected, result)
  end

  def test_discover_commands_no_method_match
    test_mod = UtilTestComposite
    test_args = {:args => ['UtilTestModule', 'test_arg', 'test_extra_arg']}
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite,
        UtilTestModule,
        "test_arg",
        "test_extra_arg"
    ]
    assert_equal(expected, result)
  end

  def test_discover_commands_extra_arg
    test_mod = UtilTestComposite
    test_args = {:args => ['UtilTestModule', 'test_command', 'test_extra_arg']}
    result = Rubycom::SingletonCommands.discover_commands(test_mod, test_args)
    expected = [
        UtilTestComposite,
        UtilTestModule,
        UtilTestModule.public_method(:test_command),
        "test_extra_arg"
    ]
    assert_equal(expected, result)
  end

  def test_get_commands
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.get_commands(test_mod)
    result.each{|k, v|
      assert(k.class == Symbol, "each key should be a symbol")
      UtilTestComposite.included_modules.include?(k)
      assert([Hash, Symbol].include?(v.class), "each value should be a Hash or a Symbol")
      assert(v == :method, "if the returned value is not a hash then it should be the symbol :method") if v.class == Symbol
    }
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
