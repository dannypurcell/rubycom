require "#{File.dirname(__FILE__)}/../../lib/rubycom.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'
require 'time'

class RubycomTest < Test::Unit::TestCase

  def capture_out(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  def capture_err(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end

  def test_run
    base = UtilTestModule
    args = %w(test_command_with_arg HelloWorld)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    expected = "test_arg=HelloWorld"
    assert_equal(expected, result)
    assert_equal(expected+"\n", result_out)
  end

  def test_run_help
    base = UtilTestModule
    args = %w(help)
    result = nil
    result_err = capture_err { result = Rubycom.run(base, args) }

    assert_equal(nil, result)
    assert(result_err.gsub(/\n|\r|\s/, '').size > 0, 'help output should not be empty')
    assert(result_err.include?('Help Requested'), 'help output should state that help was requested')
  end

  def test_run_nil_return
    base = UtilTestModule
    args = %w(test_command)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    expected_out = "command test\n\n"
    assert_equal(nil, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_hash_return
    base = UtilTestModule
    time = "#{Time.now.to_s}"
    args = ['test_command_arg_timestamp', time]
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    expected = {test_time: Time.parse(time)}
    expected_out = expected.to_yaml
    assert_equal(expected, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_all_optional
    base = UtilTestModule
    args = %w(test_command_all_options)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    e_test_arg = 'test_arg_default'
    e_test_option = 'test_option_default'
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n\n"
    assert_equal(nil, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_all_opt_override_first
    base = UtilTestModule
    args = %w(test_command_all_options test_arg_modified)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_default'
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n\n"
    assert_equal(nil, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_all_opt_override_first_alt
    base = UtilTestModule
    args = %w(test_command_all_options -test_arg=test_arg_modified)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_default'
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n\n"
    assert_equal(nil, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_all_opt_override_second
    base = UtilTestModule
    args = %w(test_command_all_options -test_option=test_option_modified)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    e_test_arg = 'test_arg_default'
    e_test_option = 'test_option_modified'
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n\n"
    assert_equal(nil, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_all_opt_use_all_opt
    base = UtilTestModule
    args = %w(test_command_all_options -test_arg=test_arg_modified -test_option=test_option_modified)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_modified'
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n\n"
    assert_equal(nil, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_all_opt_reverse
    base = UtilTestModule
    args = %w(test_command_all_options -test_option=test_option_modified -test_arg=test_arg_modified)
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    e_test_arg = 'test_arg_modified'
    e_test_option = 'test_option_modified'
    expected_out = "Output is test_arg=#{e_test_arg},test_option=#{e_test_option}\n\n"
    assert_equal(nil, result)
    assert_equal(expected_out, result_out)
  end

  def test_run_options_arr
    mod = 'util_test_module.rb'
    command = 'test_command_options_arr'
    args = 'test_option1 test_option2 1.0 false'
    expected = 'Output is test_option=test_option1,test_option_arr=["test_option2", 1.0, false]'+"\n\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_run_multi_args
    mod = 'util_test_composite.rb'
    sub_mod = 'UtilTestModule'
    command = 'test_command_with_args'
    args = 'a b'
    expected = 'test_arg=a,another_test_arg=b'+"\n\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{sub_mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_run_missing_required_arg
    base = UtilTestModule
    args = %w(test_command_with_return -test_option_int=2)
    result = nil
    result_err = capture_err { result = Rubycom.run(base, args) }
    expected = 'Missing required argument: test_arg'
    assert_equal(nil, result)
    assert(result_err.gsub(/\n|\r|\s/, '').size > 0, 'error output should not be empty')
    assert(result_err.include?(expected), "error output should include #{expected} but was #{result}")
  end

  def test_run_composite
    base = UtilTestComposite
    args = ['test_composite_command', '\'Hello Composite\'']
    result = nil
    result_out = capture_out { result = Rubycom.run(base, args) }

    expected = "Hello Composite"
    expected_out = expected+"\n"
    assert_equal(expected_out, result_out)
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = "testing_arg \"[test1, test2]\" -test_opt='testing_option' \"{a: 'test_hsh_arg'}\" -test_bool=true some other args"
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=true test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_names_with_shorts
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_names'
    args = "testing_arg \"[test1, test2]\" -opt='testing_option' -h =\"{a: 'test_hsh_arg'}\" --bool true some other args"
    expected = 'arg_test=testing_arg arr=["test1", "test2"] opt=testing_option hsh={"a"=>"test_hsh_arg"} bool=true rest_test=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_names_all_separators
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_names'
    args = "testing_arg --arr = \"[test1, test2]\" -opt= 'testing_option' -h =\"{a: 'test_hsh_arg'}\" --bool true some other args"
    expected = 'arg_test=testing_arg arr=["test1", "test2"] opt=testing_option hsh={"a"=>"test_hsh_arg"} bool=true rest_test=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_args_for_opts
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = 'testing_arg test2 testing_option test_hsh_arg true some other args'
    expected = "test_arg=testing_arg test_arr=test2 test_opt=testing_option test_hsh=test_hsh_arg test_bool=true test_rest=[\"some\", \"other\", \"args\"]"+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_solid_arr
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = "testing_arg [test1,test2] -test_opt='testing_option' \"{a: 'test_hsh_arg'}\" some other args"
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=some test_rest=["other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_quoted_solid_arr
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = 'testing_arg "[test1,test2]" -test_opt="testing_option" "{a: "test_hsh_arg"}" -test_bool=false some other args'
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=false test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_odd_sp
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = 'testing_arg "[ test1 ,  test2 ]" -test_opt="testing_option" "{ a:    "test_hsh_arg" }" -test_bool=false some other args'
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=false test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_hash_rocket
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = 'testing_arg "[ test1 ,  test2 ]" -test_opt="testing_option" "{ :a =>    "test_hsh_arg" }" false some other args'
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={ :a =>    test_hsh_arg } test_bool=false test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_rest_no_extra
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = "testing_arg \"[test1, test2]\" -test_opt='testing_option' \"{a: 'test_hsh_arg'}\""
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=true test_rest=[]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_bang_arg
    mod = 'util_test_module.rb'
    command = 'test_command_mixed_options'
    args = "! \"[test1, test2]\" -test_opt='testing_option' \"{a: 'test_hsh_arg'}\" -test_bool=true some other args"
    expected = 'test_arg=! test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=true test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

end
