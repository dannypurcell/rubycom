require "#{File.dirname(__FILE__)}/../../lib/rubycom.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'
require 'time'

class RubycomTest < Test::Unit::TestCase

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
    test_command_no_docs
    test_command_with_arg       -  A test_command with one arg
    test_command_arg_named_arg  -  A test_command with an arg named arg
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
    test_command_mixed_options  -  A test_command with several mixed options

    Default Commands:
    help                 - prints this help page
    job                  - run a job file
    register_completions - setup bash tab completion
    tab_complete         - print a list of possible matches for a given word

    END
    expected_out = expected
    assert_equal(expected.gsub(/\n|\r|\s/, ''), result.gsub(/\n|\r|\s/, ''))
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
    expected_out = "No argument available for test_arg\n"

    assert_equal(expected, result)
    assert_equal(expected_out, tst_out.lines.first)
    Rubycom::Documentation.get_command_usage(base,args[0],args[1..-1]).each_line{|expected_line|
      assert_equal(true, tst_out.lines.include?(expected_line))
    }
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

  def test_full_run_mixed_args
    mod = "util_test_module.rb"
    command = "test_command_mixed_options"
    args = "testing_arg \"[test1, test2]\" -test_opt='testing_option' \"{a: 'test_hsh_arg'}\" -test_bool=true some other args"
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=true test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_solid_arr
    mod = "util_test_module.rb"
    command = "test_command_mixed_options"
    args = "testing_arg [test1,test2] -test_opt='testing_option' \"{a: 'test_hsh_arg'}\" some other args"
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=some test_rest=["other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_quoted_solid_arr
    mod = "util_test_module.rb"
    command = "test_command_mixed_options"
    args = 'testing_arg "[test1,test2]" -test_opt="testing_option" "{a: "test_hsh_arg"}" -test_bool=false some other args'
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=false test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_odd_sp
    mod = "util_test_module.rb"
    command = "test_command_mixed_options"
    args = 'testing_arg "[ test1 ,  test2 ]" -test_opt="testing_option" "{ a:    "test_hsh_arg" }" -test_bool=false some other args'
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=false test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_hash_rocket
    mod = "util_test_module.rb"
    command = "test_command_mixed_options"
    args = 'testing_arg "[ test1 ,  test2 ]" -test_opt="testing_option" "{ :a =>    "test_hsh_arg" }" false some other args'
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={ :a =>    test_hsh_arg } test_bool=false test_rest=["some", "other", "args"]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_full_run_mixed_args_no_rest
    mod = "util_test_module.rb"
    command = "test_command_mixed_options"
    args = "testing_arg \"[test1, test2]\" -test_opt='testing_option' \"{a: 'test_hsh_arg'}\""
    expected = 'test_arg=testing_arg test_arr=["test1", "test2"] test_opt=testing_option test_hsh={"a"=>"test_hsh_arg"} test_bool=true test_rest=[]'+"\n"
    result = %x(ruby #{File.expand_path(File.dirname(__FILE__))}/#{mod} #{command} #{args})
    assert_equal(expected, result)
  end

  def test_tab_complete_nil_arg
    mod = UtilTestComposite
    args = nil
    expected = ["test_composite_command", "UtilTestNoSingleton", "UtilTestModule"]
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_empty_arg
    mod = UtilTestComposite
    args = ['']
    expected = ["test_composite_command", "UtilTestNoSingleton", "UtilTestModule"]
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_partial_module
    mod = UtilTestComposite
    args = ['Util']
    expected = ["UtilTestNoSingleton", "UtilTestModule"]
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_partial_module_single_match
    mod = UtilTestComposite
    args = ['UtilTestM']
    expected = ["UtilTestModule"]
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_whole_module
    mod = UtilTestComposite
    args = ['UtilTestModule']
    expected = ["test_command",
                "test_command_no_docs",
                "test_command_with_arg",
                "test_command_arg_named_arg",
                "test_command_with_args",
                "test_command_with_options",
                "test_command_all_options",
                "test_command_options_arr",
                "test_command_with_return",
                "test_command_arg_timestamp",
                "test_command_arg_false",
                "test_command_arg_arr",
                "test_command_arg_hash",
                "test_command_mixed_options"]
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_empty_sub_command
    mod = UtilTestComposite
    args = ['UtilTestModule', '']
    expected = ["test_command",
                "test_command_no_docs",
                "test_command_with_arg",
                "test_command_arg_named_arg",
                "test_command_with_args",
                "test_command_with_options",
                "test_command_all_options",
                "test_command_options_arr",
                "test_command_with_return",
                "test_command_arg_timestamp",
                "test_command_arg_false",
                "test_command_arg_arr",
                "test_command_arg_hash",
                "test_command_mixed_options"]
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_partial_sub_command
    mod = UtilTestComposite
    args = ['UtilTestModule', 'test_command_ar']
    expected = ["test_command_arg_named_arg",
                "test_command_arg_timestamp",
                "test_command_arg_false",
                "test_command_arg_arr",
                "test_command_arg_hash"]
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_whole_sub_command_single_match
    mod = UtilTestComposite
    args = ['UtilTestModule', 'test_command_with_options']
    expected = ['']
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_whole_sub_command_multi_match
    mod = UtilTestComposite
    args = ['UtilTestModule', 'test_command_with_arg']
    expected = ['']
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

  def test_tab_complete_whole_sub_command_with_empty
    mod = UtilTestComposite
    args = ['UtilTestModule', 'test_command_with_args', '']
    expected = ['']
    result =  Rubycom.tab_complete(mod, args)
    assert_equal(expected, result)
  end

end