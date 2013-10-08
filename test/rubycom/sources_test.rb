require "#{File.dirname(__FILE__)}/../../lib/rubycom/sources.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class SourcesTest < Test::Unit::TestCase

  def test_source_commands
    test_commands = {:UtilTestComposite=>
                         {:commands=>
                              {:UtilTestModule=>
                                   {:commands=>
                                        {:test_command=>{:type=>:command},
                                         :test_command_all_options=>{:type=>:command},
                                         :test_command_arg_arr=>{:type=>:command},
                                         :test_command_arg_false=>{:type=>:command},
                                         :test_command_arg_hash=>{:type=>:command},
                                         :test_command_arg_named_arg=>{:type=>:command},
                                         :test_command_arg_timestamp=>{:type=>:command},
                                         :test_command_mixed_options=>{:type=>:command},
                                         :test_command_no_docs=>{:type=>:command},
                                         :test_command_options_arr=>{:type=>:command},
                                         :test_command_with_arg=>{:type=>:command},
                                         :test_command_with_args=>{:type=>:command},
                                         :test_command_with_options=>{:type=>:command},
                                         :test_command_with_return=>{:type=>:command}},
                                    :type=>:module},
                               :UtilTestNoSingleton=>{:commands=>{}, :type=>:module},
                               :test_composite_command=>{:type=>:command}},
                          :type=>:module}}
    result = Rubycom::Sources.source_commands(test_commands)
    expected = {}
    assert_equal(expected, result)
  end

end
