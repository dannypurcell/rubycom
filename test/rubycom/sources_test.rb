require "#{File.dirname(__FILE__)}/../../lib/rubycom/sources.rb"

require "#{File.dirname(__FILE__)}/util_test_bin.rb"
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
    assert(result.size > 0, "should be at least one result")
    result.each{|res|
      assert(res.class == Hash, "each result should be a Hash")
      assert(res.size == 2, "each result should have two keys")
      assert(res.has_key?(:command), "each result should have a :command key")
      assert(res.has_key?(:source), "each result should have a :source key")
    }
    assert(result.select{|res|res[:command] == UtilTestComposite}.size == 1, "result should have a UtilTestComposite command")
    assert(result.select{|res|res[:command] == UtilTestModule}.size == 1, "result should have a UtilTestComposite command")
    assert(result.select{|res|res[:command] == UtilTestModule.public_method(:test_command)}.size == 1, "result should have a test_command method command")
    assert(result.select{|res|res[:command] == "test_extra_arg"}.size == 1, "result should have a test_extra_arg String command")
    assert_equal(result.select{|res|res[:command] == UtilTestComposite}.first[:source].gsub("\n",''), (File.read("#{File.dirname(__FILE__)}/util_test_composite.rb")+File.read("#{File.dirname(__FILE__)}/util_test_sub_module.rb")+File.read("#{File.dirname(__FILE__)}/util_test_bin.rb")).gsub("\n",''))
    assert_equal(result.select{|res|res[:command] == UtilTestModule}.first[:source].gsub("\n",''), (File.read("#{File.dirname(__FILE__)}/util_test_module.rb")).gsub("\n",''))
    assert_equal(result.select{|res|res[:command] == UtilTestModule.public_method(:test_command)}.first[:source].gsub("\n",''), "# A basic test command\n  def self.test_command\n    puts 'command test'\n  end\n".gsub("\n",''))
    assert_equal(result.select{|res|res[:command] == "test_extra_arg"}.first[:source].gsub("\n",''), "test_extra_arg")
  end

  def test_source_command_run
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
    bin_file = File.read("#{File.dirname(__FILE__)}/util_test_bin.rb")
    lib_file = File.read("#{File.dirname(__FILE__)}/util_test_composite.rb")
    assert(result.include?(bin_file),"source for composite module #{test_command} must include bin_file")
    assert(result.include?(lib_file),"source for composite module #{test_command} must include lib_file")
  end
end
