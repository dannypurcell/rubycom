require "#{File.dirname(__FILE__)}/../../lib/rubycom/yard_doc.rb"

require "#{File.dirname(__FILE__)}/../../lib/rubycom/sources.rb"
require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class YardDocTest < Test::Unit::TestCase

  def test_document_commands
    test_commands = [
        UtilTestComposite,
        UtilTestModule,
        UtilTestModule.public_method(:test_command),
        "test_extra_arg"
    ]
    test_source_plugin = Rubycom::Sources
    result = Rubycom::YardDoc.document_commands(test_commands, test_source_plugin)
    expected = [
        {
            :command => UtilTestComposite,
            :doc => {
                :full_doc => "",
                :short_doc => "",
                :sub_command_docs => {
                    :UtilTestModule => "A command module used for testing.",
                    :UtilTestNoSingleton => "",
                    :test_composite_command => "A test_command in a composite console."
                }
            }
        },
        {
            :command => UtilTestModule,
            :doc => {
                :full_doc =>
                    "A command module used for testing\n\nThis module contains most of the test case input methods.",
                :short_doc => "A command module used for testing.",
                :sub_command_docs => {
                    :test_command => "A basic test command.",
                    :test_command_all_options => "A test_command with all optional arguments.",
                    :test_command_arg_arr => "A test_command with an array argument.",
                    :test_command_arg_false => "A test_command with a Boolean argument.",
                    :test_command_arg_hash => "A test_command with an Hash argument.",
                    :test_command_arg_named_arg => "A test_command with an arg named arg.",
                    :test_command_arg_timestamp => "A test_command with a Timestamp argument and an unnecessarily long description which should overflow when\nit tries to line up with other descriptions.",
                    :test_command_mixed_options => "A test_command with several mixed options.",
                    :test_command_nil_option => "A test_command with a nil optional argument.",
                    :test_command_no_docs => "",
                    :test_command_options_arr => "A test_command with an options array.",
                    :test_command_with_arg => "A test_command with one arg.",
                    :test_command_with_args => "A test_command with two args.",
                    :test_command_with_options => "A test_command with an optional argument.",
                    :test_command_with_return => "A test_command with a return argument."
                }
            }
        },
        {
            :command => UtilTestModule.public_method(:test_command),
            :doc => {
                :full_doc => "A basic test command",
                :parameters => [],
                :short_doc => "A basic test command.",
                :tags => []
            }
        },
        {:command => "test_extra_arg", :doc => {:full_doc => "", :short_doc => ""}}
    ]
    assert_equal(expected, result)
  end

  def test_document_command_command_run
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_source_plugin = Rubycom::Sources
    result = Rubycom::YardDoc.document_command(test_command, test_source_plugin)
    expected = {
        :full_doc => "A test_command with a return argument",
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req},
            {:default => 1, :doc => "an optional test argument which happens to be an Integer", :doc_type => "Integer", :param_name => "test_option_int", :type => :opt}
        ],
        :short_doc => "A test_command with a return argument.",
        :tags => [
            {:name => "test_arg", :tag_name => "param", :text => "a test argument", :types => ["String"]},
            {:name => "test_option_int", :tag_name => "param", :text => "an optional test argument which happens to be an Integer", :types => ["Integer"]},
            {:name => nil, :tag_name => "return", :text => "an array including both params if test_option_int != 1", :types => ["Array"]},
            {:name => nil, :tag_name => "return", :text => "the first param if test_option_int == 1", :types => ["String"]}
        ]
    }
    assert_equal(expected, result)
  end

  def test_document_command_command_run_rest
    test_command = UtilTestModule.public_method(:test_command_mixed_options)
    test_source_plugin = Rubycom::Sources
    result = Rubycom::YardDoc.document_command(test_command, test_source_plugin)
    expected = {
        :full_doc => "A test_command with several mixed options",
        :parameters => [
            {:default => nil, :doc => "", :doc_type => "", :param_name => "test_arg", :type => :req},
            {:default => [], :doc => "", :doc_type => "", :param_name => "test_arr", :type => :opt},
            {:default => "test_opt_arg", :doc => "", :doc_type => "", :param_name => "test_opt", :type => :opt},
            {:default => {}, :doc => "", :doc_type => "", :param_name => "test_hsh", :type => :opt},
            {:default => true, :doc => "", :doc_type => "", :param_name => "test_bool", :type => :opt},
            {:default => [], :doc => "", :doc_type => "", :param_name => "*test_rest", :type => :rest}
        ],
        :short_doc => "A test_command with several mixed options.",
        :tags => []
    }
    assert_equal(expected, result)
  end

  def test_document_command_run_module
    test_command = UtilTestModule
    test_source_plugin = Rubycom::Sources
    result = Rubycom::YardDoc.document_command(test_command, test_source_plugin)
    expected = {
        :full_doc => "A command module used for testing\n\nThis module contains most of the test case input methods.",
        :short_doc => "A command module used for testing.",
        :sub_command_docs => {
            :test_command => "A basic test command.",
            :test_command_all_options => "A test_command with all optional arguments.",
            :test_command_arg_arr => "A test_command with an array argument.",
            :test_command_arg_false => "A test_command with a Boolean argument.",
            :test_command_arg_hash => "A test_command with an Hash argument.",
            :test_command_arg_named_arg => "A test_command with an arg named arg.",
            :test_command_arg_timestamp =>
                "A test_command with a Timestamp argument and an unnecessarily long description which should overflow when\nit tries to line up with other descriptions.",
            :test_command_mixed_options => "A test_command with several mixed options.",
            :test_command_nil_option=>"A test_command with a nil optional argument.",
            :test_command_no_docs => "",
            :test_command_options_arr => "A test_command with an options array.",
            :test_command_with_arg => "A test_command with one arg.",
            :test_command_with_args => "A test_command with two args.",
            :test_command_with_options => "A test_command with an optional argument.",
            :test_command_with_return => "A test_command with a return argument."
        }
    }
    assert_equal(expected, result)
  end

  def test_document_command_run_composite
    test_command = UtilTestComposite
    test_source_plugin = Rubycom::Sources
    result = Rubycom::YardDoc.document_command(test_command, test_source_plugin)
    expected = {
        :full_doc => "",
        :short_doc => "",
        :sub_command_docs => {
            :UtilTestModule => "A command module used for testing.",
            :UtilTestNoSingleton => "",
            :test_composite_command => "A test_command in a composite console."
        }
    }
    assert_equal(expected, result)
  end

end
