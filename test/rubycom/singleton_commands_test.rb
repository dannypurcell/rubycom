require "#{File.dirname(__FILE__)}/../../lib/rubycom/singleton_commands.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class SingletonCommandsTest < Test::Unit::TestCase

  def test_discover_commands
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.discover_commands(test_mod)
    expected = {:UtilTestComposite=>
                    {:commands=>
                         {:UtilTestModule=>
                              {:commands=>
                                   {:test_command=>{:type=>:command},
                                    :test_command_all_options=>{:type=>:command},
                                    :test_command_arg_arr=>{:type=>:command},
                                    :test_command_arg_false=>{:type=>:command},
                                    :test_command_arg_hash=>{:type=>:command},
                                    :test_command_arg_named_arg=>{:type=>:command},
                                    :test_command_arg_timestamp=>{:type=>:command},
                                    :test_command_mixed_options=>{:type=>:command},
                                    :test_command_no_docs=>{:type=>:command},
                                    :test_command_options_arr=>{:type=>:command},
                                    :test_command_with_arg=>{:type=>:command},
                                    :test_command_with_args=>{:type=>:command},
                                    :test_command_with_options=>{:type=>:command},
                                    :test_command_with_return=>{:type=>:command}},
                               :type=>:module},
                          :UtilTestNoSingleton=>{:commands=>{}, :type=>:module},
                          :test_composite_command=>{:type=>:command}},
                     :type=>:module}}
    assert_equal(expected, result)
  end

  def test_get_top_level_commands
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.get_top_level_commands(test_mod)
    expected = {:UtilTestComposite=>
                    {:commands=>
                         {:UtilTestModule=>{:type=>:module},
                          :UtilTestNoSingleton=>{:type=>:module},
                          :test_composite_command=>{:type=>:command}},
                     :type=>:module}}
    assert_equal(expected, result)
  end

  def test_get_commands
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.get_commands(test_mod)
    expected = {:UtilTestComposite=>
                    {:commands=>
                         {:UtilTestModule=>
                              {:commands=>
                                   {:test_command=>{:type=>:command},
                                    :test_command_all_options=>{:type=>:command},
                                    :test_command_arg_arr=>{:type=>:command},
                                    :test_command_arg_false=>{:type=>:command},
                                    :test_command_arg_hash=>{:type=>:command},
                                    :test_command_arg_named_arg=>{:type=>:command},
                                    :test_command_arg_timestamp=>{:type=>:command},
                                    :test_command_mixed_options=>{:type=>:command},
                                    :test_command_no_docs=>{:type=>:command},
                                    :test_command_options_arr=>{:type=>:command},
                                    :test_command_with_arg=>{:type=>:command},
                                    :test_command_with_args=>{:type=>:command},
                                    :test_command_with_options=>{:type=>:command},
                                    :test_command_with_return=>{:type=>:command}},
                               :type=>:module},
                          :UtilTestNoSingleton=>{:commands=>{}, :type=>:module},
                          :test_composite_command=>{:type=>:command}},
                     :type=>:module}}
    assert_equal(expected, result)
  end

  def test_get_commands_all_false
    test_mod = UtilTestComposite
    result = Rubycom::SingletonCommands.get_commands(test_mod, false)
    expected = {:UtilTestComposite=>
                    {:commands=>
                         {:UtilTestModule=>{:type=>:module},
                          :UtilTestNoSingleton=>{:type=>:module},
                          :test_composite_command=>{:type=>:command}},
                     :type=>:module}}
    assert_equal(expected, result)
  end

end
