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

class TestClassNoSingleton
  def test_method
    "TEST_INSTANCE_METHOD"
  end
end

require 'test/unit'
#noinspection RubyInstanceMethodNamingConvention
class TestSimpleNumber < Test::Unit::TestCase

  def test_retrieve_method_hash
    method = TestClass.public_method(:test_command)
    result_hash = {}
    YARD.parse_string(File.read(__FILE__)).enumerator.each { |sexp|
      result_hash = Rubycom.retrieve_method_hash(sexp, method) if result_hash.length == 0
    }
    assert_equal('A basic test command', result_hash[:method_doc])
  end

  def test_get_doc
    method = TestClass.public_method(:test_command_with_return)
    result_hash = Rubycom.get_doc(method)
    assert_equal('A test_command with a return argument', result_hash[:desc])
    assert_equal(2, result_hash[:params].size)
    assert_equal('[String] test_arg a test argument', result_hash[:params][0])
    assert_equal('[Integer] test_option_int an optional test argument which happens to be an Integer', result_hash[:params][1])
    assert_equal(2, result_hash[:return].size)
    assert_equal('[Array] a array including both params if test_option_int != 1', result_hash[:return][0])
    assert_equal('[String] a the first param if test_option_int == 1', result_hash[:return][1])
  end

  def test_get_command_usage
    base = TestClass
    command_name = 'test_command_arg_false'
    result = Rubycom.get_command_usage(base, command_name)
    expected = <<-END.gsub(/^ {4}/, '')
    Command: test_command_arg_false
        Usage: test_command_arg_false [-test_flag=val]
        Parameters:
            Boolean - test_flag a test Boolean argument
        Returns:
            [Boolean] the flag passed in
    END
    assert_equal(expected, result)
  end

  def test_get_command_usage_nil_base
    base = nil
    command_name = 'test_command'
    assert_raise(NameError) { Rubycom.get_command_usage(base, command_name) }
  end

  def test_get_command_usage_nil_command
    base = TestClass
    command_name = nil
    result = Rubycom.get_command_usage(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_usage_no_command
    base = TestClass
    command_name = ''
    result = Rubycom.get_command_usage(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_usage_bad_base
    base = ":asd"
    command_name = 'test_command_with_options'
    assert_raise(NameError) { Rubycom.get_command_usage(base, command_name) }
  end

  def test_get_command_usage_invalid_command
    base = TestClass
    command_name = '123asd!@#'
    assert_raise(NameError) { Rubycom.get_command_usage(base, command_name) }
  end

  def test_get_command_summary
    base = TestClass
    command_name = 'test_command_with_options'
    result = Rubycom.get_command_summary(base, command_name)
    assert_equal("test_command_with_options - A test_command with an optional argument\n", result)
  end

  def test_get_command_summary_no_command
    base = TestClass
    command_name = ''
    result = Rubycom.get_command_summary(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_summary_nil_base
    base = nil
    command_name = 'test_command_with_options'
    assert_raise(NameError) { Rubycom.get_command_summary(base, command_name) }
  end

  def test_get_command_summary_nil_command
    base = TestClass
    command_name = nil
    result = Rubycom.get_command_summary(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_summary_wrong_base
    base = TestClassNoSingleton
    command_name = 'test_command_with_options'
    assert_raise(NameError) { Rubycom.get_command_summary(base, command_name) }
  end

  def test_get_command_summary_bad_command
    base = TestClass
    command_name = '!_fail_command_'
    assert_raise(NameError) { Rubycom.get_command_summary(base, command_name) }
  end

  def test_get_usage
    base = TestClass
    result = Rubycom.get_usage(base)
    expected = <<-END.gsub(/^ {4}/, '')
    Commands:
    Command: test_command
        Usage: test_command
        Returns:
            void

    Command: test_command_with_arg
        Usage: test_command_with_arg test_arg
        Parameters:
            String - test_arg a test argument
        Returns:
            void

    Command: test_command_with_args
        Usage: test_command_with_args test_arg another_test_arg
        Parameters:
            String - test_arg a test argument
            String - another_test_arg another test argument
        Returns:
            void

    Command: test_command_with_options
        Usage: test_command_with_options test_arg [-test_option=val]
        Parameters:
            String - test_arg a test argument
            String - test_option an optional test argument
        Returns:
            void

    Command: test_command_with_return
        Usage: test_command_with_return test_arg [-test_option_int=val]
        Parameters:
            String - test_arg a test argument
            Integer - test_option_int an optional test argument which happens to be an Integer
        Returns:
            [Array] a array including both params if test_option_int != 1
            [String] a the first param if test_option_int == 1

    Command: test_command_arg_timestamp
        Usage: test_command_arg_timestamp test_time
        Parameters:
            Timestamp - test_time a test Timestamp argument
        Returns:
            [Hash] a hash including the given argument

    Command: test_command_arg_false
        Usage: test_command_arg_false [-test_flag=val]
        Parameters:
            Boolean - test_flag a test Boolean argument
        Returns:
            [Boolean] the flag passed in

    Command: test_command_arg_arr
        Usage: test_command_arg_arr [-test_arr=val]
        Parameters:
            Array - test_arr an Array test argument
        Returns:
            void

    Command: test_command_arg_hash
        Usage: test_command_arg_hash [-test_hash=val]
        Parameters:
            Hash - test_hash a Hash test argument
        Returns:
            void

    END
    assert_equal(expected, result)
  end

  def test_get_usage_nil_base
    base = nil
    result = Rubycom.get_usage(base)
    assert_equal('', result)
  end

  def test_get_usage_no_singleton_base
    base = TestClassNoSingleton
    result = Rubycom.get_usage(base)
    assert_equal('', result)
  end

  def test_get_summary
    base = TestClass
    result = Rubycom.get_summary(base)
    expected = <<-END.gsub(/^ {4}/, '')
    Commands:
      test_command - A basic test command
      test_command_with_arg - A test_command with one arg
      test_command_with_args - A test_command with two args
      test_command_with_options - A test_command with an optional argument
      test_command_with_return - A test_command with a return argument
      test_command_arg_timestamp - A test_command with a Timestamp argument
      test_command_arg_false - A test_command with a Boolean argument
      test_command_arg_arr - A test_command with an array argument
      test_command_arg_hash - A test_command with an Hash argument
    END
    assert_equal(expected, result)
  end

  def test_get_summary_nil_base
    base = nil
    result = Rubycom.get_summary(base)
    assert_equal('', result)
  end

  def test_get_summary_no_singleton_base
    base = TestClassNoSingleton
    result = Rubycom.get_summary(base)
    assert_equal('', result)
  end

  def test_get_commands
    test_command_list = TestClass.singleton_methods(false)
    result_command_list = Rubycom.get_commands(TestClass)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_commands_nil_base
    test_command_list = nil.singleton_methods(false)
    result_command_list = Rubycom.get_commands(nil)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_commands_no_singleton_base
    test_command_list = []
    result_command_list = Rubycom.get_commands(TestClassNoSingleton)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_parse_arg_string
    test_arg = "test_arg"
    result = Rubycom.parse_arg(test_arg)
    expected = "test_arg"
    assert_equal(expected, result)
  end

  def test_parse_arg_fixnum
    test_arg = "1234512415435"
    result = Rubycom.parse_arg(test_arg)
    expected = 1234512415435
    assert_equal(expected, result)
  end

  def test_parse_arg_float
    test_arg = "12345.67890"
    result = Rubycom.parse_arg(test_arg)
    expected = 12345.67890
    assert_equal(expected, result)
  end

  def test_parse_arg_timestamp
    time = Time.new
    test_arg = time.to_s
    result = Rubycom.parse_arg(test_arg)
    expected = time
    assert_equal(expected.to_i, result.to_i)
  end

  def test_parse_arg_datetime
    time = Time.new("2013-05-08 00:00:00 -0500")
    date = Date.new(time.year, time.month, time.day)
    test_arg = date.to_s
    result = Rubycom.parse_arg(test_arg)
    expected = date
    assert_equal(expected, result)
  end

  def test_parse_arg_array
    test_arg = ["1",2,"a",'b']
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = test_arg
    assert_equal(expected, result)
  end

  def test_parse_arg_hash
    time = Time.new.to_s
    test_arg = ":a: \"#{time}\""
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = {a: time}
    assert_equal(expected, result)
  end

  def test_parse_arg_hash_group
    test_arg = ":a: [1,2]\n:b: 1\n:c: test\n:d: 1.0\n:e: \"2013-05-08 23:21:52 -0500\"\n"
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = {:a=>[1, 2], :b=>1, :c=>"test", :d=>1.0, :e=>"2013-05-08 23:21:52 -0500"}
    assert_equal(expected, result)
  end

  def test_parse_arg_yaml
    test_arg = { :a=>["1",2,"a",'b'], :b=>1, :c=>"test", :d=>"#{Time.now.to_s}" }
    result = Rubycom.parse_arg(test_arg.to_yaml)
    expected = test_arg
    assert_equal(expected, result)
  end

  def test_parse_arg_code
    test_arg = 'def self.test_code_method; raise "Fail - test_parse_arg_code";end'
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = test_arg
    assert_equal(expected, result)
  end

  def test_run
    tst_out = ''
    def tst_out.write(data); self << data; end
    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stdout = $stderr, tst_out

    base = TestClass
    args = ["test_command_with_arg","HelloWorld"]
    result = Rubycom.run(base,args)

    expected = "test_arg=HelloWorld"
    expected_out = expected
    assert_equal(expected, result)
    assert_equal(expected_out, tst_out.chomp)
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_nil_return
    tst_out = ''
    def tst_out.write(data); self << data; end
    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stdout = $stderr, tst_out

    base = TestClass
    args = ["test_command"]
    result = Rubycom.run(base,args)

    expected = nil
    expected_out = "command test\n"
    assert_equal(expected, result)
    assert_equal(expected_out, tst_out.chomp)
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_hash_return
    tst_out = ''
    def tst_out.write(data); self << data; end
    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stdout = $stderr, tst_out

    base = TestClass
    time = Time.now.to_s
    args = ["test_command_arg_timestamp", time]
    result = Rubycom.run(base,args)

    expected = {:test_time=>Time.parse(time)}
    expected_out = {test_time: Time.parse(time) }.to_yaml
    assert_equal(expected, result)
    assert_equal(expected_out, tst_out)
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end
end