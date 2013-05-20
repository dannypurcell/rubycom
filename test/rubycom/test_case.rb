require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require 'time'


class TestClass

  # A basic test non-command method
  def non_command
    puts 'fail'
  end

  # A basic test command
  def self.test_command
    puts 'command test'
  end

  # A test_command with one arg
  #
  # @param [String] test_arg a test argument
  def self.test_command_with_arg(test_arg)
    "test_arg=#{test_arg}"
  end

  # A test_command with two args
  # @param [String] test_arg a test argument
  # @param [String] another_test_arg another test argument
  def self.test_command_with_args(test_arg, another_test_arg)
    puts "test_arg=#{test_arg},another_test_arg=#{another_test_arg}"
  end

  # A test_command with an optional argument
  # @param [String] test_arg a test argument
  # @param [String] test_option an optional test argument
  def self.test_command_with_options(test_arg, test_option='option_default')
    puts "test_arg=#{test_arg},test_option=#{test_option}"
  end

  # A test_command with all optional arguments
  # @param [String] test_arg an optional test argument
  # @param [String] test_option another optional test argument
  def self.test_command_all_options(test_arg='test_arg_default', test_option='test_option_default')
    puts "Output is test_arg=#{test_arg},test_option=#{test_option}"
  end

  # A test_command with an options array
  # @param [String] test_option an optional test argument
  # @param [String] test_options an optional array of arguments
  def self.test_command_options_arr (
      test_option="test_option_default",
          *test_options
  )
    test_options.each{|arg|
      puts "#{arg} is a #{arg.class}"
    }
    puts "Output is test_option=#{test_option},test_option_arr=#{test_options}"
  end

  # A test_command with a return argument
  #
  # @param [String] test_arg a test argument
  # @param [Integer] test_option_int an optional test argument which happens to be an Integer
  # @return [Array] a array including both params if test_option_int != 1
  # @return [String] a the first param if test_option_int == 1
  def self.test_command_with_return(test_arg, test_option_int=1)
    ret = [test_arg, test_option_int]
    if test_option_int == 1
      ret = test_arg
    end
    ret
  end

  # A test_command with a Timestamp argument
  # @param [Timestamp] test_time a test Timestamp argument
  # @return [Hash] a hash including the given argument
  def self.test_command_arg_timestamp(test_time)
    {test_time: test_time}
  end

  # A test_command with a Boolean argument
  # @param [Boolean] test_flag a test Boolean argument
  # @return [Boolean] the flag passed in
  def self.test_command_arg_false(test_flag=false)
    test_flag
  end

  # A test_command with an array argument
  #
  # @param [Array] test_arr an Array test argument
  def self.test_command_arg_arr(test_arr=[])
    test_arr
  end

  # A test_command with an Hash argument
  # @param [Hash] test_hash a Hash test argument
  def self.test_command_arg_hash(test_hash={})
    test_hash
  end
end


require 'test/unit'
#noinspection RubyInstanceMethodNamingConvention
class TestCase < Test::Unit::TestCase
  def test
    base = TestClass
    args = ["test_command_with_return", "-test_option_int=2"]
    result = Rubycom.run(base, args)
    puts result
  end
end