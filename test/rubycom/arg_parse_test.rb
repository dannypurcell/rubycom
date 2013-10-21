require "#{File.dirname(__FILE__)}/../../lib/rubycom/arg_parse.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class ArgParseTest < Test::Unit::TestCase

  def test_parse_string
    test_arg = "test_arg"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:args => ["test_arg"]}
    assert_equal(expected, result)
  end

  def test_parse_empty
    test_arg = ""
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {}
    assert_equal(expected, result)
  end

  def test_parse_fixnum
    test_arg = "1234512415435"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:args => [1234512415435]}
    assert_equal(expected, result)
  end

  def test_parse_float
    test_arg = "12345.67890"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:args => [12345.6789]}
    assert_equal(expected, result)
  end

  def test_parse_timestamp
    time = Time.new
    test_arg = "'#{time.to_s}'"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:args => [YAML.load(time.to_s)]}
    assert_equal(expected, result)
  end

  def test_parse_datetime
    time = Time.new('2013-05-08 00:00:00 -0500')
    date = Date.new(time.year, time.month, time.day)
    test_arg = "'#{date.to_s}'"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:args => [YAML.load(date.to_s)]}
    assert_equal(expected, result)
  end

  def test_parse_array
    test_arg = "'[\"1\", 2, \"a\", 'b']'"
    result = Rubycom::ArgParse.parse_command_line(test_arg.to_s)
    expected = {:args => [["1", 2, "a", "b"]]}
    assert_equal(expected, result)
  end

  def test_parse_hash
    time = Time.new.to_s
    test_arg = "'{a: \"#{time}\"}'"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {args: [{'a' => time}]}
    assert_equal(expected, result)
  end

  def test_parse_hash_group
    test_arg = "':a: [1,2]\n:b: 1\n:c: test\n:d: 1.0\n:e: \"2013-05-08 23:21:52 -0500\"\n'"
    result = Rubycom::ArgParse.parse_command_line(test_arg.to_s)
    expected = {:args => [{:a => [1, 2], :b => 1, :c => "test", :d => 1.0, :e => "2013-05-08 23:21:52 -0500"}]}
    assert_equal(expected, result)
  end

  def test_parse_yaml
    time_str = Time.now.to_s
    test_arg = {:a => ["1", 2, "a", 'b'], :b => 1, :c => "test", :d => "#{time_str}"}
    result = Rubycom::ArgParse.parse_command_line("'#{test_arg.to_yaml}'")
    expected = {:args => [{:a => ["1", 2, "a", "b"], :b => 1, :c => "test", :d => "#{time_str}"}]}
    assert_equal(expected, result)
  end

  def test_parse_code
    test_arg = "'def self.test_code_method; raise \"Fail - test_parse_code\";end'"
    result = Rubycom::ArgParse.parse_command_line(test_arg.to_s)
    expected = {:args => ["def self.test_code_method; raise \"Fail - test_parse_code\";end"]}
    assert_equal(expected, result)
  end

  def test_parse_opt_string_eq
    test_arg = "-test_arg=\"test\""
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:opts => {"test_arg" => "test"}}
    assert_equal(expected, result)
  end

  def test_parse_opt_string_sp
    test_arg = "-test_arg \"test\""
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:opts => {"test_arg" => "test"}}
    assert_equal(expected, result)
  end

  def test_parse_opt_long_string_eq
    test_arg = '--test_arg="test"'
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:opts => {"test_arg" => "test"}}
    assert_equal(expected, result)
  end

  def test_parse_opt_long_string_sp
    test_arg = "--test_arg \"test\""
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:opts => {"test_arg" => "test"}}
    assert_equal(expected, result)
  end

  def test_parse_multi_mention
    test_arg = "--other='testing' --test_arg \"test\" --test_arg \"thing\""
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:opts => {"other" => "testing", "test_arg" => ["test", "thing"]}}
    assert_equal(expected, result)
  end

  def test_parse_flag_true_short
    test_arg = "-t"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:flags => {"t" => true}}
    assert_equal(expected, result)
  end

  def test_parse_flag_true_long
    test_arg = "--test_flag"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:flags => {"test_flag" => true}}
    assert_equal(expected, result)
  end

  def test_parse_flag_false_short
    test_arg = "-no-t"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:flags => {"t" => false}}
    assert_equal(expected, result)
  end

  def test_parse_flag_false_long
    test_arg = "--no-test_flag"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:flags => {"test_flag" => false}}
    assert_equal(expected, result)
  end

  def test_parse_command_run
    test_arg = "UtilTestModule test_command_with_return testing_argument --test_option_int=10"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:args => ["UtilTestModule", "test_command_with_return", "testing_argument"], :opts => {"test_option_int" => 10}}
    assert_equal(expected, result)
  end

  def test_parse_command_run_mixed
    test_arg = "UtilTestModule test_command_mixed_options testing_arg \"[test1, test2]\" -test_opt='testing_option' \"{a: 'test_hsh_arg'}\" -test_bool=true some other args"
    result = Rubycom::ArgParse.parse_command_line(test_arg)
    expected = {:args => ["UtilTestModule", "test_command_mixed_options", "testing_arg", ["test1", "test2"], {"a" => "test_hsh_arg"}, "some", "other", "args"], :opts => {"test_bool" => true, "test_opt" => "testing_option"}}
    assert_equal(expected, result)
  end

end
