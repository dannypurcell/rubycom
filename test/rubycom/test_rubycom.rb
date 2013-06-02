require 'time'

require "#{File.expand_path(File.dirname(__FILE__))}/util_test_module.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_composite.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_no_singleton.rb"

require 'test/unit'
#noinspection RubyInstanceMethodNamingConvention
class TestRubycom < Test::Unit::TestCase

  def test_get_doc
    method = UtilTestModule.public_method(:test_command_with_return)
    result_hash = Rubycom.get_doc(method)
    assert_equal('A test_command with a return argument'.gsub(/\n|\r|\s/, ''), result_hash[:desc].join("\n").gsub(/\n|\r|\s/, ''))
    assert_equal(2, result_hash[:param].size)
    assert_equal('[String] test_arg a test argument'.gsub(/\n|\r|\s/, ''), result_hash[:param][0].gsub(/\n|\r|\s/, ''))
    assert_equal('[Integer] test_option_int an optional test argument which happens to be an Integer'.gsub(/\n|\r|\s/, ''), result_hash[:param][1].gsub(/\n|\r|\s/, ''))
    assert_equal(2, result_hash[:return].size)
    assert_equal('[Array] an array including both params if test_option_int != 1'.gsub(/\n|\r|\s/, ''), result_hash[:return][0].gsub(/\n|\r|\s/, ''))
    assert_equal('[String] a the first param if test_option_int == 1'.gsub(/\n|\r|\s/, ''), result_hash[:return][1].gsub(/\n|\r|\s/, ''))
  end

  def test_get_command_usage
    base = UtilTestModule
    command_name = 'test_command_arg_false'
    result = Rubycom.get_command_usage(base, command_name)
    expected = <<-END.gsub(/^ {4}/, '')
    Usage: test_command_arg_false [-test_flag=val]
    Parameters:
        [Boolean] test_flag a test Boolean argument
    Returns:
        [Boolean] the flag passed in
    END
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_command_usage_nil_base
    base = nil
    command_name = 'test_command'
    assert_raise(Rubycom::CLIError) { Rubycom.get_command_usage(base, command_name) }
  end

  def test_get_command_usage_nil_command
    base = UtilTestModule
    command_name = nil
    result = Rubycom.get_command_usage(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_usage_no_command
    base = UtilTestModule
    command_name = ''
    result = Rubycom.get_command_usage(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_usage_bad_base
    base = ":asd"
    command_name = 'test_command_with_options'
    assert_raise(Rubycom::CLIError) { Rubycom.get_command_usage(base, command_name) }
  end

  def test_get_command_usage_invalid_command
    base = UtilTestModule
    command_name = '123asd!@#'
    assert_raise(Rubycom::CLIError) { Rubycom.get_command_usage(base, command_name) }
  end

  def test_get_command_summary
    base = UtilTestModule
    command_name = 'test_command_with_options'
    result = Rubycom.get_command_summary(base, command_name)
    assert_equal("test_command_with_options - A test_command with an optional argument\n".gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_command_summary_no_command
    base = UtilTestModule
    command_name = ''
    result = Rubycom.get_command_summary(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_summary_nil_base
    base = nil
    command_name = 'test_command_with_options'
    assert_raise(Rubycom::CLIError) { Rubycom.get_command_summary(base, command_name) }
  end

  def test_get_command_summary_nil_command
    base = UtilTestModule
    command_name = nil
    result = Rubycom.get_command_summary(base, command_name)
    assert_equal('No command specified.', result)
  end

  def test_get_command_summary_wrong_base
    base = UtilTestNoSingleton
    command_name = 'test_command_with_options'
    assert_raise(Rubycom::CLIError) { Rubycom.get_command_summary(base, command_name) }
  end

  def test_get_command_summary_bad_command
    base = UtilTestModule
    command_name = '!_fail_command_'
    assert_raise(Rubycom::CLIError) { Rubycom.get_command_summary(base, command_name) }
  end

  def test_get_usage
    base = UtilTestModule
    result = Rubycom.get_usage(base)
    expected = <<-END.gsub(/^ {4}/, '')
    Usage:
      UtilTestModule <command> [args]

    Commands:
      test_command                -  A basic test command
      test_command_with_arg       -  A test_command with one arg
      test_command_with_args      -  A test_command with two args
      test_command_with_options   -  A test_command with an optional argument
      test_command_all_options    -  A test_command with all optional arguments
      test_command_options_arr    -  A test_command with an options array
      test_command_with_return    -  A test_command with a return argument
      test_command_arg_timestamp  -  A test_command with a Timestamp argument and an unnecessarily
                                     long description which should overflow when
                                     it tries to line up with other descriptions.
      test_command_arg_false      -  A test_command with a Boolean argument
      test_command_arg_arr        -  A test_command with an array argument
      test_command_arg_hash       -  A test_command with an Hash argument

    END
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_usage_nil_base
    base = nil
    result = Rubycom.get_usage(base)
    assert_equal('', result)
  end

  def test_get_usage_no_singleton_base
    base = UtilTestNoSingleton
    result = Rubycom.get_usage(base)
    assert_equal('', result)
  end

  def test_get_summary
    base = UtilTestModule
    result = Rubycom.get_summary(base)
    expected = <<-END.gsub(/^ {4}/, '')
    Commands:
    test_command                -  A basic test command
    test_command_with_arg       -  A test_command with one arg
    test_command_with_args      -  A test_command with two args
    test_command_with_options   -  A test_command with an optional argument
    test_command_all_options    -  A test_command with all optional arguments
    test_command_options_arr    -  A test_command with an options array
    test_command_with_return    -  A test_command with a return argument
    test_command_arg_timestamp  -  A test_command with a Timestamp argument and an unnecessarily
                                   long description which should overflow when it tries to line up
                                   with other descriptions.
    test_command_arg_false      -  A test_command with a Boolean argument
    test_command_arg_arr        -  A test_command with an array argument
    test_command_arg_hash       -  A test_command with an Hash argument
    END
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
  end

  def test_get_summary_nil_base
    base = nil
    result = Rubycom.get_summary(base)
    assert_equal('No Commands found for .', result)
  end

  def test_get_summary_no_singleton_base
    base = UtilTestNoSingleton
    result = Rubycom.get_summary(base)
    assert_equal('No Commands found for UtilTestNoSingleton.', result)
  end

  def test_get_top_level_commands
    test_command_list = [:test_command, :test_command_with_arg, :test_command_with_args, :test_command_with_options,
                         :test_command_all_options, :test_command_options_arr, :test_command_with_return,
                         :test_command_arg_timestamp, :test_command_arg_false, :test_command_arg_arr,
                         :test_command_arg_hash]
    result_command_list = Rubycom.get_top_level_commands(UtilTestModule)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_top_level_commands_nil_base
    test_command_list = []
    result_command_list = Rubycom.get_top_level_commands(nil)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_commands_nil_base
    test_command_list = []
    result_command_list = Rubycom.get_commands(nil)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_get_top_level_commands_singleton_base
    test_command_list = []
    result_command_list = Rubycom.get_top_level_commands(UtilTestNoSingleton)
    assert_equal(test_command_list.length, result_command_list.length)
    test_command_list.each { |sym|
      assert_includes(result_command_list, sym)
    }
  end

  def test_parse_arg_string
    test_arg = "test_arg"
    result = Rubycom.parse_arg(test_arg)
    expected = {arg: "test_arg"}
    assert_equal(expected, result)
  end

  def test_parse_arg_fixnum
    test_arg = "1234512415435"
    result = Rubycom.parse_arg(test_arg)
    expected = {arg: 1234512415435}
    assert_equal(expected, result)
  end

  def test_parse_arg_float
    test_arg = "12345.67890"
    result = Rubycom.parse_arg(test_arg)
    expected = {arg: 12345.67890}
    assert_equal(expected, result)
  end

  def test_parse_arg_timestamp
    time = Time.new
    test_arg = time.to_s
    result = Rubycom.parse_arg(test_arg)
    expected = {arg: time}
    assert_equal(expected[:arg].to_i, result[:arg].to_i)
  end

  def test_parse_arg_datetime
    time = Time.new("2013-05-08 00:00:00 -0500")
    date = Date.new(time.year, time.month, time.day)
    test_arg = date.to_s
    result = Rubycom.parse_arg(test_arg)
    expected = {arg: date}
    assert_equal(expected, result)
  end

  def test_parse_arg_array
    test_arg = ["1", 2, "a", 'b']
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = {arg: test_arg}
    assert_equal(expected, result)
  end

  def test_parse_arg_hash
    time = Time.new.to_s
    test_arg = ":a: \"#{time}\""
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = {arg: {a: time}}
    assert_equal(expected, result)
  end

  def test_parse_arg_hash_group
    test_arg = ":a: [1,2]\n:b: 1\n:c: test\n:d: 1.0\n:e: \"2013-05-08 23:21:52 -0500\"\n"
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = {arg: {:a => [1, 2], :b => 1, :c => "test", :d => 1.0, :e => "2013-05-08 23:21:52 -0500"}}
    assert_equal(expected, result)
  end

  def test_parse_arg_yaml
    test_arg = {:a => ["1", 2, "a", 'b'], :b => 1, :c => "test", :d => "#{Time.now.to_s}"}
    result = Rubycom.parse_arg(test_arg.to_yaml)
    expected = {arg: test_arg}
    assert_equal(expected, result)
  end

  def test_parse_arg_code
    test_arg = 'def self.test_code_method; raise "Fail - test_parse_arg_code";end'
    result = Rubycom.parse_arg(test_arg.to_s)
    expected = {arg: 'def self.test_code_method; raise "Fail - test_parse_arg_code";end'}
    assert_equal(expected, result)
  end

  def test_run
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_with_arg", "HelloWorld"]
    result = Rubycom.run(base, args)

    expected = "test_arg=HelloWorld"
    expected_out = expected
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_help
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["help"]
    result = Rubycom.run(base, args)

    expected = <<-END.gsub(/^ {4}/,'')
    Usage:
        UtilTestModule <command> [args]

    Commands:
    test_command                -  A basic test command
    test_command_with_arg       -  A test_command with one arg
    test_command_with_args      -  A test_command with two args
    test_command_with_options   -  A test_command with an optional argument
    test_command_all_options    -  A test_command with all optional arguments
    test_command_options_arr    -  A test_command with an options array
    test_command_with_return    -  A test_command with a return argument
    test_command_arg_timestamp  -  A test_command with a Timestamp argument and an unnecessarily
                                   long description which should overflow when
                                   it tries to line up with other descriptions.
    test_command_arg_false      -  A test_command with a Boolean argument
    test_command_arg_arr        -  A test_command with an array argument
    test_command_arg_hash       -  A test_command with an Hash argument
    END
    expected_out = expected
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_nil_return
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command"]
    result = Rubycom.run(base, args)

    expected = nil
    expected_out = "command test\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_hash_return
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    time = Time.now.to_s
    args = ["test_command_arg_timestamp", time]
    result = Rubycom.run(base, args)

    expected = {:test_time => Time.parse(time)}
    expected_out = {test_time: Time.parse(time)}.to_yaml
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_all_optional
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_all_options"]
    result = Rubycom.run(base, args)

    e_test_arg = 'test_arg_default'
    e_test_option = 'test_option_default'
    expected = nil
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_all_opt_override_first
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_all_options", "test_arg_modified"]
    result = Rubycom.run(base, args)

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_default'
    expected = nil
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_all_opt_override_first_alt
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_all_options", "-test_arg=test_arg_modified"]
    result = Rubycom.run(base, args)

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_default'
    expected = nil
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_all_opt_override_second
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_all_options", "-test_option=test_option_modified"]
    result = Rubycom.run(base, args)

    e_test_arg = 'test_arg_default'
    e_test_option = 'test_option_modified'
    expected = nil
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_all_opt_use_all_opt
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_all_options", "-test_arg=test_arg_modified", "-test_option=test_option_modified"]
    result = Rubycom.run(base, args)

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_modified'
    expected = nil
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_all_opt_reverse
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_all_options", "-test_option=test_option_modified", "-test_arg=test_arg_modified"]
    result = Rubycom.run(base, args)

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_modified'
    expected = nil
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_options_arr
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_options_arr", "test_option1", "test_option2", 1.0, false]
    result = Rubycom.run(base, args)

    e_test_arg = 'test_option1'
    e_test_options = ["test_option2", 1.0, false]
    expected = nil
    expected_out = "Output is test_option=#{e_test_arg},test_option_arr=#{e_test_options}\n"
    assert_equal(expected, result)
    assert_equal(expected_out.gsub(/\n|\r|\s/, ''), tst_out.gsub(/\n|\r|\s/, ''))
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_missing_required_arg
    tst_out = ''

    def tst_out.puts(data)
      self << data.to_s << "\n"
      nil
    end

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestModule
    args = ["test_command_with_return", "-test_option_int=2"]
    result = Rubycom.run(base, args)

    expected = nil
    expected_out = "No argument available for test_arg"
    assert_equal(expected, result)
    assert_equal(expected_out, tst_out.split(/\n|\r|\r\n/).first)
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

  def test_run_composite
    tst_out = ''

    def tst_out.write(data)
      self << data
    end

    o_stdout, $stdout = $stdout, tst_out
    o_stderr, $stderr = $stderr, tst_out

    base = UtilTestComposite
    args = ["test_composite_command", "Hello Composite"]
    result = Rubycom.run(base, args)

    expected = "Hello Composite"
    expected_out = "Hello Composite"
    assert_equal(expected, result)
    assert_equal(expected_out, tst_out.split(/\n|\r|\r\n/).first)
  ensure
    $stdout = o_stdout
    $stderr = o_stderr
  end

end