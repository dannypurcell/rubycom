require "#{File.dirname(__FILE__)}/../../lib/rubycom/sources.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class SourcesTest < Test::Unit::TestCase

  def test_source_commands
    test_commands = [
        UtilTestComposite,
        UtilTestModule,
        UtilTestModule.public_method(:test_command),
        "test_extra_arg"
    ]
    result = Rubycom::Sources.source_commands(test_commands)
    expected = [
        {:command => UtilTestComposite, :source => File.read("#{File.dirname(__FILE__)}/util_test_composite.rb") },
        {:command => UtilTestModule, :source => File.read("#{File.dirname(__FILE__)}/util_test_module.rb") },
        {:command => UtilTestModule.public_method(:test_command), :source => "# A basic test command\n  def self.test_command\n    puts 'command test'\n  end\n"},
        {:command => "test_extra_arg", :source => "test_extra_arg"}
    ]
    assert_equal(expected, result)
  end

  def test_source_command_command_run
    test_command = UtilTestModule.public_method(:test_command_with_return)
    result = Rubycom::Sources.source_command(test_command)
    expected = "# A test_command with a return argument\n#\n# @param [String] test_arg a test argument\n# @param [Integer] test_option_int an optional test argument which happens to be an Integer\n# @return [Array] an array including both params if test_option_int != 1\n# @return [String] the first param if test_option_int == 1\n  def self.test_command_with_return(test_arg, test_option_int=1)\n    ret = [test_arg, test_option_int]\n    if test_option_int == 1\n      ret = test_arg\n    end\n    ret\n  end\n"
    assert_equal(expected, result)
  end

  def test_source_command_run_module
    test_command = UtilTestModule
    result = Rubycom::Sources.source_command(test_command)
    expected = File.read("#{File.dirname(__FILE__)}/util_test_module.rb")
    assert_equal(expected, result)
  end

  def test_source_command_run_composite
    test_command = UtilTestComposite
    result = Rubycom::Sources.source_command(test_command)
    expected = File.read("#{File.dirname(__FILE__)}/util_test_composite.rb")
    assert_equal(expected, result)
  end
end
