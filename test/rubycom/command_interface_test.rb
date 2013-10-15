require "#{File.dirname(__FILE__)}/../../lib/rubycom/command_interface.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class CommandInterfaceTest < Test::Unit::TestCase

  def test_build_interface_module
    test_command = UtilTestModule
    test_doc = {
        :short_doc => "A command module used for testing.",
        :full_doc => "A command module used for testing\n\nThis module contains most of the test case input methods.",
        :sub_command_docs => {
            :non_command => "A test non-command method.",
            :test_command => "A basic test command.",
            :test_command_no_docs => "",
            :test_command_with_arg => "A test_command with one arg.",
            :test_command_arg_named_arg => "A test_command with an arg named arg.",
            :test_command_with_args => "A test_command with two args.",
            :test_command_with_options => "A test_command with an optional argument.",
            :test_command_all_options => "A test_command with all optional arguments.",
            :test_command_options_arr => "A test_command with an options array.",
            :test_command_with_return => "A test_command with a return argument.",
            :test_command_arg_timestamp => "A test_command with a Timestamp argument and an unnecessarily long description which should overflow when it tries to line up with other descriptions.",
            :test_command_arg_false => "A test_command with a Boolean argument.",
            :test_command_arg_arr => "A test_command with an array argument.",
            :test_command_arg_hash => "A test_command with an Hash argument.",
            :test_command_mixed_options => "A test_command with several mixed options."
        }
    }
    result = Rubycom::CommandInterface.build_interface(test_command, test_doc)

    assert_true(result.gsub(/\s|\n|\r\n/,'').include?(test_doc[:full_doc].gsub(/\s|\n|\r\n/,'')),"#{result} should include #{test_doc[:full_doc]}")
    test_doc[:sub_command_docs].each{|cmd,doc|
      assert_true(result.include?(cmd.to_s),"#{result} should include #{cmd.to_s}")
      assert_true(result.gsub(/\s|\n|\r\n/,'').include?(doc.gsub(/\s|\n|\r\n/,'')),"#{result} should include #{doc}")
    }
  end

  def test_build_interface_method
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_doc = {
        :full_doc => "A test_command with a return argument",
        :short_doc => "A test_command with a return argument.",
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :required => true},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :required => false}
        ],
        :tags => [
            {:name => "test_arg", :tag_name => "param", :text => "a test argument", :types => ["String"]},
            {:name => "test_option_int", :tag_name => "param", :text => "an optional test argument which happens to be an Integer", :types => ["Integer"]},
            {:name => nil, :tag_name => "return", :text => "an array including both params if test_option_int != 1", :types => ["Array"]},
            {:name => nil, :tag_name => "return", :text => "a the first param if test_option_int == 1", :types => ["String"]}
        ]
    }
    result = Rubycom::CommandInterface.build_interface(test_command, test_doc)

    assert_true(result.gsub(/\s|\n|\r\n/,'').include?(test_doc[:full_doc].gsub(/\s|\n|\r\n/,'')),"#{result} should include #{test_doc[:full_doc]}")
    test_doc[:tags].each{|tag|
      if tag[:name].nil?
        assert_true(result.include?(tag[:tag_name].to_s),"#{result} should include #{tag[:tag_name].to_s}")
      else
        assert_true(result.include?(tag[:name].to_s),"#{result} should include #{tag[:name].to_s}")
      end
      assert_true(result.gsub(/\s|\n|\r\n/,'').include?("#{tag[:types]}"),"#{result} should include #{tag[:types]}")
      assert_true(result.gsub(/\s|\n|\r\n/,'').include?(tag[:text].gsub(/\s|\n|\r\n/,'')),"#{result} should include #{tag[:text]}")
    }
  end

  def test_build_usage_module
    test_command = UtilTestModule
    test_doc = {
        :short_doc => "A command module used for testing.",
        :full_doc => "A command module used for testing\n\nThis module contains most of the test case input methods.",
        :sub_command_docs => {
            :non_command => "A test non-command method.",
            :test_command => "A basic test command.",
            :test_command_no_docs => "",
            :test_command_with_arg => "A test_command with one arg.",
            :test_command_arg_named_arg => "A test_command with an arg named arg.",
            :test_command_with_args => "A test_command with two args.",
            :test_command_with_options => "A test_command with an optional argument.",
            :test_command_all_options => "A test_command with all optional arguments.",
            :test_command_options_arr => "A test_command with an options array.",
            :test_command_with_return => "A test_command with a return argument.",
            :test_command_arg_timestamp => "A test_command with a Timestamp argument and an unnecessarily long description which should overflow when it tries to line up with other descriptions.",
            :test_command_arg_false => "A test_command with a Boolean argument.",
            :test_command_arg_arr => "A test_command with an array argument.",
            :test_command_arg_hash => "A test_command with an Hash argument.",
            :test_command_mixed_options => "A test_command with several mixed options."
        }
    }
    result = Rubycom::CommandInterface.build_usage(test_command, test_doc)

    assert_true(result.include?(test_command.to_s),"#{result} should include #{test_command.to_s}")
  end

  def test_build_usage_method
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_doc = {
        :full_doc => "A test_command with a return argument",
        :short_doc => "A test_command with a return argument.",
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :required => true},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :required => false}
        ],
        :tags => [
            {:name => "test_arg", :tag_name => "param", :text => "a test argument", :types => ["String"]},
            {:name => "test_option_int", :tag_name => "param", :text => "an optional test argument which happens to be an Integer", :types => ["Integer"]},
            {:name => nil, :tag_name => "return", :text => "an array including both params if test_option_int != 1", :types => ["Array"]},
            {:name => nil, :tag_name => "return", :text => "the first param if test_option_int == 1", :types => ["String"]}
        ]
    }
    result = Rubycom::CommandInterface.build_usage(test_command, test_doc)

    assert_true(result.include?(test_command.name.to_s),"#{result} should include #{test_command.name.to_s}")
    test_doc[:parameters].each{|param|
      if param[:required]
        assert_true(result.include?("<#{param[:param_name]}>"),"#{result} should include <#{param[:param_name]}>")
      else
        assert_true(result.include?(param[:param_name]),"#{result} should include #{param[:param_name]}")
      end
    }
  end

  def test_build_options_module
    test_command = UtilTestModule
    test_doc = {
        :short_doc => "A command module used for testing.",
        :full_doc => "A command module used for testing\n\nThis module contains most of the test case input methods.",
        :sub_command_docs => {
            :non_command => "A test non-command method.",
            :test_command => "A basic test command.",
            :test_command_no_docs => "",
            :test_command_with_arg => "A test_command with one arg.",
            :test_command_arg_named_arg => "A test_command with an arg named arg.",
            :test_command_with_args => "A test_command with two args.",
            :test_command_with_options => "A test_command with an optional argument.",
            :test_command_all_options => "A test_command with all optional arguments.",
            :test_command_options_arr => "A test_command with an options array.",
            :test_command_with_return => "A test_command with a return argument.",
            :test_command_arg_timestamp => "A test_command with a Timestamp argument and an unnecessarily long description which should overflow when it tries to line up with other descriptions.",
            :test_command_arg_false => "A test_command with a Boolean argument.",
            :test_command_arg_arr => "A test_command with an array argument.",
            :test_command_arg_hash => "A test_command with an Hash argument.",
            :test_command_mixed_options => "A test_command with several mixed options."
        }
    }
    result = Rubycom::CommandInterface.build_options(test_command, test_doc)

    assert_true(result.include?("[command]"),"#{result} should include [command]")
  end

  def test_build_options_method
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_doc = {
        :full_doc => "A test_command with a return argument",
        :short_doc => "A test_command with a return argument.",
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :required => true},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :required => false}
        ],
        :tags => [
            {:name => "test_arg", :tag_name => "param", :text => "a test argument", :types => ["String"]},
            {:name => "test_option_int", :tag_name => "param", :text => "an optional test argument which happens to be an Integer", :types => ["Integer"]},
            {:name => nil, :tag_name => "return", :text => "an array including both params if test_option_int != 1", :types => ["Array"]},
            {:name => nil, :tag_name => "return", :text => "the first param if test_option_int == 1", :types => ["String"]}
        ]
    }
    result = Rubycom::CommandInterface.build_options(test_command, test_doc)

    test_doc[:parameters].each{|param|
      if param[:required]
        assert_true(result.include?("<#{param[:param_name]}>"),"#{result} should include <#{param[:param_name]}>")
      else
        assert_true(result.include?(param[:param_name]),"#{result} should include #{param[:param_name]}")
      end
    }
  end

  def test_build_details_module
    test_command = UtilTestModule
    test_doc = {
        :short_doc => "A command module used for testing.",
        :full_doc => "A command module used for testing\n\nThis module contains most of the test case input methods.",
        :sub_command_docs => {
            :non_command => "A test non-command method.",
            :test_command => "A basic test command.",
            :test_command_no_docs => "",
            :test_command_with_arg => "A test_command with one arg.",
            :test_command_arg_named_arg => "A test_command with an arg named arg.",
            :test_command_with_args => "A test_command with two args.",
            :test_command_with_options => "A test_command with an optional argument.",
            :test_command_all_options => "A test_command with all optional arguments.",
            :test_command_options_arr => "A test_command with an options array.",
            :test_command_with_return => "A test_command with a return argument.",
            :test_command_arg_timestamp => "A test_command with a Timestamp argument and an unnecessarily long description which should overflow when it tries to line up with other descriptions.",
            :test_command_arg_false => "A test_command with a Boolean argument.",
            :test_command_arg_arr => "A test_command with an array argument.",
            :test_command_arg_hash => "A test_command with an Hash argument.",
            :test_command_mixed_options => "A test_command with several mixed options."
        }
    }
    result = Rubycom::CommandInterface.build_details(test_command, test_doc)

    assert_true(result.include?("Sub Commands:"),"#{result} should include Sub Commands:")
    test_doc[:sub_command_docs].each{|cmd,doc|
      assert_true(result.include?(cmd.to_s),"#{result} should include #{cmd.to_s}")
      assert_true(result.gsub(/\s|\n|\r\n/,'').include?(doc.gsub(/\s|\n|\r\n/,'')),"#{result} should include #{doc}")
    }
  end

  def test_build_details_method
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_doc = {
        :full_doc => "A test_command with a return argument",
        :short_doc => "A test_command with a return argument.",
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :required => true},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :required => false}
        ],
        :tags => [
            {:name => "test_arg", :tag_name => "param", :text => "a test argument", :types => ["String"]},
            {:name => "test_option_int", :tag_name => "param", :text => "an optional test argument which happens to be an Integer", :types => ["Integer"]},
            {:name => nil, :tag_name => "return", :text => "an array including both params if test_option_int != 1", :types => ["Array"]},
            {:name => nil, :tag_name => "return", :text => "the first param if test_option_int == 1", :types => ["String"]}
        ]
    }
    result = Rubycom::CommandInterface.build_details(test_command, test_doc)

    assert_true(result.include?("Parameters:"),"#{result} should include Parameters:")
    assert_true(result.include?("Returns:"),"#{result} should include Returns:")
    test_doc[:tags].each{|tag|
      if tag[:name].nil?
        assert_true(result.include?(tag[:tag_name].to_s),"#{result} should include #{tag[:tag_name].to_s}")
      else
        assert_true(result.include?(tag[:name].to_s),"#{result} should include #{tag[:name].to_s}")
      end
      assert_true(result.gsub(/\s|\n|\r\n/,'').include?("#{tag[:types]}"),"#{result} should include #{tag[:types]}")
      assert_true(result.gsub(/\s|\n|\r\n/,'').include?(tag[:text].gsub(/\s|\n|\r\n/,'')),"#{result} should include #{tag[:text]}")
    }
  end

end
