require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
# A command module used for testing
#
#This module contains most of the test case input methods.
module UtilTestModule

  # A test non-command method
  def non_command
    puts 'fail'
  end

  # A basic test command
  def self.test_command
    puts 'command test'
  end

  def self.test_command_no_docs
    puts 'command test'
  end

  # A test_command with one arg
  #
  # @param [String] test_arg a test argument
  def self.test_command_with_arg(test_arg)
    "test_arg=#{test_arg}"
  end

  # A test_command with an arg named arg
  #
  # @param [String] arg a test argument whose parameter name is arg
  def self.test_command_arg_named_arg(arg)
    "arg=#{arg}"
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

  # A test_command with a nil optional argument
  # @param [String] test_arg a test argument
  # @param [String] test_option an optional test argument with a nil default value
  # @return [String] a message including the value and class of each parameter
  def self.test_command_nil_option(test_arg, test_option=nil)
    "test_arg=#{test_arg}, test_arg.class=#{test_arg.class}, test_option=#{test_option}, test_option.class=#{test_option.class}"
  end

  # A test_command with an options array
  # @param [String] test_option an optional test argument
  # @param [Array] test_options an optional array of arguments
  def self.test_command_options_arr (
      test_option='test_option_default',
          *test_options
  )
    puts "Output is test_option=#{test_option},test_option_arr=#{test_options}"
  end

  # A test_command with a return argument
  #
  # @param [String] test_arg a test argument
  # @param [Integer] test_option_int an optional test argument which happens to be an Integer
  # @return [Array] an array including both params if test_option_int != 1
  # @return [String] the first param if test_option_int == 1
  def self.test_command_with_return(test_arg, test_option_int=1)
    ret = [test_arg, test_option_int]
    if test_option_int == 1
      ret = test_arg
    end
    ret
  end

  # A test_command with a Timestamp argument and an unnecessarily long description which should overflow when
  # it tries to line up with other descriptions.
  #
  # some more stuff
  #
  # @param [Timestamp] test_time a test Timestamp argument
  # @return [Hash] a hash including the given argument
  def self.test_command_arg_timestamp(test_time)
    {:test_time => test_time}
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

  # A test_command with several mixed options
  #
  # @param [String] test_arg
  # @param [Array] test_arr
  # @param [String] test_opt
  # @param [Fixnum] test_opt
  def self.test_command_mixed_options(test_arg, test_arr=[], test_opt='test_opt_arg', test_hsh={}, test_bool=true, *test_rest)
    "test_arg=#{test_arg} test_arr=#{test_arr} test_opt=#{test_opt} test_hsh=#{test_hsh} test_bool=#{test_bool} test_rest=#{test_rest}"
  end

  # A test_command with several mixed options with varying names
  #
  # @param [Object] arg_test anything
  # @param [Array] arr an array of things
  # @param [String] opt an optional string
  # @param [Hash] hsh a hash representing some test keys and values
  # @param [TrueClass|FalseClass] bool a true or false
  # @param [Array] rest_test everything else
  def self.test_command_mixed_names(arg_test, arr=[], opt='test_opt_arg', hsh={}, bool=true, *rest_test)
    "arg_test=#{arg_test} arr=#{arr} opt=#{opt} hsh=#{hsh} bool=#{bool} rest_test=#{rest_test}"
  end

  include Rubycom
end
