require "#{File.dirname(__FILE__)}/../../lib/rubycom/completions.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class CompletionsTest < Test::Unit::TestCase

  def test_tab_complete_nil
    base = nil
    arguments = nil
    command_plugin = nil
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = []
    assert_equal(expected, result)
  end

  def test_tab_complete_empty
    base = ''
    arguments = []
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = []
    assert_equal(expected, result)
  end

  def test_tab_complete_command_empty
    base = UtilTestModule
    arguments = []
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = UtilTestModule.singleton_methods(false).map{|n|n.to_s}
    assert_equal(expected, result)
  end

  def test_tab_complete_command_single_match
    base = UtilTestModule
    arguments = ['test_command']
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = []
    assert_equal(expected, result)
  end

  def test_tab_complete_command_all_match
    base = UtilTestModule
    arguments = ['test_']
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = UtilTestModule.singleton_methods(false).map{|n|n.to_s}
    assert_equal(expected, result)
  end

  def test_tab_complete_command_partial_match
    base = UtilTestModule
    arguments = ['test_command_with']
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = UtilTestModule.singleton_methods(false).map{|n|n.to_s}.select{|n|n.start_with?(arguments[0])}
    assert_equal(expected, result)
  end

  def test_tab_complete_module_empty
    base = UtilTestComposite
    arguments = []
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = UtilTestComposite.singleton_methods(false).map{|n|n.to_s}+
        UtilTestComposite.included_modules.reject{|n|n == Rubycom}.map{|n|n.to_s}
    assert_equal(expected, result)
  end

  def test_tab_complete_module_partial_match
    base = UtilTestComposite
    arguments = ['Util']
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = UtilTestComposite.included_modules.reject{|n|n == Rubycom}.map{|n|n.to_s}
    assert_equal(expected, result)
  end

  def test_tab_complete_module_single_match
    base = UtilTestComposite
    arguments = ['UtilTestModule']
    command_plugin = Rubycom::SingletonCommands
    result = Rubycom::Completions.tab_complete(base, arguments, command_plugin)
    expected = UtilTestModule.singleton_methods(false).map{|n|n.to_s}
    assert_equal(expected, result)
  end

end

