require "#{File.dirname(__FILE__)}/../../lib/rubycom/arguments.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class ArgumentsTest < Test::Unit::TestCase

  def test_parse_arg_string
    test_arg = "test_arg"
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {rubycom_non_opt_arg: "test_arg"}
    assert_equal(expected, result)
  end

  def test_parse_arg_fixnum
    test_arg = "1234512415435"
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {rubycom_non_opt_arg: 1234512415435}
    assert_equal(expected, result)
  end

  def test_parse_arg_float
    test_arg = "12345.67890"
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {rubycom_non_opt_arg: 12345.67890}
    assert_equal(expected, result)
  end

  def test_parse_arg_timestamp
    time = Time.new
    test_arg = time.to_s
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {rubycom_non_opt_arg: time}
    assert_equal(expected[:rubycom_non_opt_arg].to_i, result[:rubycom_non_opt_arg].to_i)
  end

  def test_parse_arg_datetime
    time = Time.new("2013-05-08 00:00:00 -0500")
    date = Date.new(time.year, time.month, time.day)
    test_arg = date.to_s
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {rubycom_non_opt_arg: date}
    assert_equal(expected, result)
  end

  def test_parse_arg_array
    test_arg = ["1", 2, "a", 'b']
    result = Rubycom::Arguments.parse_arg(test_arg.to_s)
    expected = {rubycom_non_opt_arg: test_arg}
    assert_equal(expected, result)
  end

  def test_parse_arg_hash
    time = Time.new.to_s
    test_arg = ":a: \"#{time}\""
    result = Rubycom::Arguments.parse_arg(test_arg.to_s)
    expected = {rubycom_non_opt_arg: {a: time}}
    assert_equal(expected, result)
  end

  def test_parse_arg_hash_group
    test_arg = ":a: [1,2]\n:b: 1\n:c: test\n:d: 1.0\n:e: \"2013-05-08 23:21:52 -0500\"\n"
    result = Rubycom::Arguments.parse_arg(test_arg.to_s)
    expected = {rubycom_non_opt_arg: {:a => [1, 2], :b => 1, :c => "test", :d => 1.0, :e => "2013-05-08 23:21:52 -0500"}}
    assert_equal(expected, result)
  end

  def test_parse_arg_yaml
    test_arg = {:a => ["1", 2, "a", 'b'], :b => 1, :c => "test", :d => "#{Time.now.to_s}"}
    result = Rubycom::Arguments.parse_arg(test_arg.to_yaml)
    expected = {rubycom_non_opt_arg: test_arg}
    assert_equal(expected, result)
  end

  def test_parse_arg_code
    test_arg = 'def self.test_code_method; raise "Fail - test_parse_arg_code";end'
    result = Rubycom::Arguments.parse_arg(test_arg.to_s)
    expected = {rubycom_non_opt_arg: 'def self.test_code_method; raise "Fail - test_parse_arg_code";end'}
    assert_equal(expected, result)
  end

  def test_parse_opt_string_eq
    test_arg = "-test_arg=\"test\""
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {test_arg: "test"}
    assert_equal(expected, result)
  end

  def test_parse_opt_string_sp
    test_arg = "-test_arg \"test\""
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {test_arg: "test"}
    assert_equal(expected, result)
  end

  def test_parse_opt_long_string_eq
    test_arg = "--test_arg=\"test\""
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {test_arg: "test"}
    assert_equal(expected, result)
  end

  def test_parse_opt_long_string_sp
    test_arg = "--test_arg \"test\""
    result = Rubycom::Arguments.parse_arg(test_arg)
    expected = {test_arg: "test"}
    assert_equal(expected, result)
  end

  def test_get_param_definitions
    test_method = UtilTestModule.public_method('test_command_with_args')
    expected = {:test_arg => {:def => "test_arg", :type => :req, :default => :nil_rubycom_required_param}, :another_test_arg => {:def => "another_test_arg", :type => :req, :default => :nil_rubycom_required_param}}
    result = Rubycom::Arguments.get_param_definitions(test_method)
    assert_equal(expected, result)
  end

  def test_get_param_definitions_no_args
    test_method = UtilTestModule.public_method('test_command')
    expected = {}
    result = Rubycom::Arguments.get_param_definitions(test_method)
    assert_equal(expected, result)
  end

  def test_get_param_definitions_arr_param
    test_method = UtilTestModule.public_method('test_command_options_arr')
    expected = {:test_option => {:def => "test_option=\"test_option_default\"", :type => :opt, :default => "test_option_default"}, :test_options => {:def => "*test_options", :type => :rest, :default => :nil_rubycom_required_param}}
    result = Rubycom::Arguments.get_param_definitions(test_method)
    assert_equal(expected, result)
  end

  def test_get_param_definitions_all_options
    test_method = UtilTestModule.public_method('test_command_all_options')
    expected = {:test_arg => {:def => "test_arg='test_arg_default'", :type => :opt, :default => "test_arg_default"}, :test_option => {:def => "test_option='test_option_default'", :type => :opt, :default => "test_option_default"}}
    result = Rubycom::Arguments.get_param_definitions(test_method)
    assert_equal(expected, result)
  end

  def test_get_param_definitions_mixed
    test_method = UtilTestModule.public_method('test_command_with_options')
    expected = {:test_arg => {:def => "test_arg", :type => :req, :default => :nil_rubycom_required_param}, :test_option => {:def => "test_option='option_default'", :type => :opt, :default => "option_default"}}
    result = Rubycom::Arguments.get_param_definitions(test_method)
    assert_equal(expected, result)
  end

  def test_parse_args_no_params
    test_method = UtilTestModule.public_method(:test_command)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = []
    expected = nil
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_one_param
    test_method = UtilTestModule.public_method(:test_command_with_arg)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["abc"]
    expected = {:test_arg=>"abc"}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_one_param_array
    test_method = UtilTestModule.public_method(:test_command_with_arg)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["[a,b,c,1,2,3]"]
    expected = {:test_arg=>['a','b','c',1,2,3]}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_one_param_hash
    test_method = UtilTestModule.public_method(:test_command_with_arg)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["{abc: 123}"]
    expected = {:test_arg=>{"abc"=>123}}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_too_many_args
    test_method = UtilTestModule.public_method(:test_command)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["123"]
    expected = nil
    result = nil
    assert_raise Rubycom::RubycomError do
      result = Rubycom::Arguments.resolve(params, arguments)
    end
    assert_equal(expected, result)
  end

  def test_parse_args_too_few_args
    test_method = UtilTestModule.public_method(:test_command_with_arg)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = []
    expected = nil
    result = nil
    assert_raise Rubycom::RubycomError do
      result = Rubycom::Arguments.resolve(params, arguments)
    end
    assert_equal(expected, result)
  end

  def test_parse_args_with_options
    test_method = UtilTestModule.public_method(:test_command_with_options)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = [";asd"]
    expected = {:test_arg=>";asd", :test_option=>"option_default"}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_with_options_filled
    test_method = UtilTestModule.public_method(:test_command_with_options)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["[1,2,3]","--test_option=abc"]
    expected = {:test_arg=>[1, 2, 3], :test_option=>"abc"}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_all_options
    test_method = UtilTestModule.public_method(:test_command_all_options)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = []
    expected = {:test_arg=>"test_arg_default", :test_option=>"test_option_default"}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_all_opts_args_entered
    test_method = UtilTestModule.public_method(:test_command_all_options)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["[1,2,3]","abc"]
    expected = {:test_arg=>[1, 2, 3], :test_option=>"abc"}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_all_opts_filled
    test_method = UtilTestModule.public_method(:test_command_all_options)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["-test_arg='123asd'","--test_option=[b,c,d]"]
    expected = {:test_arg=>"123asd", :test_option=>["b","c","d"]}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_arr_option
    test_method = UtilTestModule.public_method(:test_command_arg_arr)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["--test_arr=['123','abc']"]
    expected = {:test_arr=>["123","abc"]}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_options_arr
    test_method = UtilTestModule.public_method(:test_command_options_arr)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = [",a2","1","2","3","a","b","c"]
    expected = {:test_option=>",a2", :test_options=>[1, 2, 3, "a", "b", "c"]}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_options_arr_with_arr
    test_method = UtilTestModule.public_method(:test_command_options_arr)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = [",a2","[1,2,3,a,b,c]"]
    expected = {:test_option=>",a2", :test_options=>[[1, 2, 3, "a", "b", "c"]]}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

  def test_parse_args_hash
    test_method = UtilTestModule.public_method(:test_command_arg_hash)
    params = Rubycom::Arguments.get_param_definitions(test_method)
    arguments = ["{testing: 'arg1', 123: 'abc', abc: 123}"]
    expected = {:test_hash=>{"testing"=>"arg1", 123=>"abc", "abc"=>123}}
    result = Rubycom::Arguments.resolve(params, arguments)
    assert_equal(expected, result)
  end

end
