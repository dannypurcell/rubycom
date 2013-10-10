require "#{File.dirname(__FILE__)}/../../lib/rubycom/yard_doc.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class YardDocTest < Test::Unit::TestCase

  def test_document_commands
    test_commands = [
        {:command => UtilTestComposite, :source => "#!/usr/bin/env ruby\nrequire \"\#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb\"\nrequire \"\#{File.expand_path(File.dirname(__FILE__))}/util_test_module.rb\"\nrequire \"\#{File.expand_path(File.dirname(__FILE__))}/util_test_no_singleton.rb\"\n\nmodule UtilTestComposite\n  include UtilTestModule\n\n  include UtilTestNoSingleton\n\n  # A test_command in a composite console\n  #\n  # @param [String] test_arg a test argument\n  # @return [String] the test arg\n  def self.test_composite_command(test_arg)\n    test_arg\n  end\n\n  include Rubycom\nend\n"},
        {:command => UtilTestModule, :source => "require \"\#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb\"\n# A command module used for testing\n#\n#This module contains most of the test case input methods.\nmodule UtilTestModule\n\n  # A test non-command method\n  def non_command\n    puts 'fail'\n  end\n\n  # A basic test command\n  def self.test_command\n    puts 'command test'\n  end\n\n  def self.test_command_no_docs\n    puts 'command test'\n  end\n\n  # A test_command with one arg\n  #\n  # @param [String] test_arg a test argument\n  def self.test_command_with_arg(test_arg)\n    \"test_arg=\#{test_arg}\"\n  end\n\n  # A test_command with an arg named arg\n  #\n  # @param [String] arg a test argument whose parameter name is arg\n  def self.test_command_arg_named_arg(arg)\n    \"arg=\#{arg}\"\n  end\n\n  # A test_command with two args\n  # @param [String] test_arg a test argument\n  # @param [String] another_test_arg another test argument\n  def self.test_command_with_args(test_arg, another_test_arg)\n    puts \"test_arg=\#{test_arg},another_test_arg=\#{another_test_arg}\"\n  end\n\n  # A test_command with an optional argument\n  # @param [String] test_arg a test argument\n  # @param [String] test_option an optional test argument\n  def self.test_command_with_options(test_arg, test_option='option_default')\n    puts \"test_arg=\#{test_arg},test_option=\#{test_option}\"\n  end\n\n  # A test_command with all optional arguments\n  # @param [String] test_arg an optional test argument\n  # @param [String] test_option another optional test argument\n  def self.test_command_all_options(test_arg='test_arg_default', test_option='test_option_default')\n    puts \"Output is test_arg=\#{test_arg},test_option=\#{test_option}\"\n  end\n\n  # A test_command with an options array\n  # @param [String] test_option an optional test argument\n  # @param [Array] test_options an optional array of arguments\n  def self.test_command_options_arr (\n      test_option='test_option_default',\n          *test_options\n  )\n    puts \"Output is test_option=\#{test_option},test_option_arr=\#{test_options}\"\n  end\n\n  # A test_command with a return argument\n  #\n  # @param [String] test_arg a test argument\n  # @param [Integer] test_option_int an optional test argument which happens to be an Integer\n  # @return [Array] an array including both params if test_option_int != 1\n  # @return [String] a the first param if test_option_int == 1\n  def self.test_command_with_return(test_arg, test_option_int=1)\n    ret = [test_arg, test_option_int]\n    if test_option_int == 1\n      ret = test_arg\n    end\n    ret\n  end\n\n  # A test_command with a Timestamp argument and an unnecessarily long description which should overflow when\n  # it tries to line up with other descriptions.\n  #\n  # some more stuff\n  #\n  # @param [Timestamp] test_time a test Timestamp argument\n  # @return [Hash] a hash including the given argument\n  def self.test_command_arg_timestamp(test_time)\n    {test_time: test_time}\n  end\n\n  # A test_command with a Boolean argument\n  # @param [Boolean] test_flag a test Boolean argument\n  # @return [Boolean] the flag passed in\n  def self.test_command_arg_false(test_flag=false)\n    test_flag\n  end\n\n  # A test_command with an array argument\n  #\n  # @param [Array] test_arr an Array test argument\n  def self.test_command_arg_arr(test_arr=[])\n    test_arr\n  end\n\n  # A test_command with an Hash argument\n  # @param [Hash] test_hash a Hash test argument\n  def self.test_command_arg_hash(test_hash={})\n    test_hash\n  end\n\n  # A test_command with several mixed options\n  def self.test_command_mixed_options(test_arg, test_arr=[], test_opt='test_opt_arg', test_hsh={}, test_bool=true, *test_rest)\n    \"test_arg=\#{test_arg} test_arr=\#{test_arr} test_opt=\#{test_opt} test_hsh=\#{test_hsh} test_bool=\#{test_bool} test_rest=\#{test_rest}\"\n  end\n\n  include Rubycom\nend\n"},
        {:command => UtilTestModule.public_method(:test_command), :source => "# A basic test command\n  def self.test_command\n    puts 'command test'\n  end\n"},
        {:command => "test_extra_arg", :source => "test_extra_arg"}
    ]
    result = Rubycom::YardDoc.document_commands(test_commands)
    expected = [
        {
            :command => UtilTestComposite,
            :doc => {
                :full_doc => "",
                :short_doc => "",
                :sub_command_docs => {
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
                    :non_command => "A test non-command method.",
                    :test_command => "A basic test command.",
                    :test_command_all_options => "A test_command with all optional arguments.",
                    :test_command_arg_arr => "A test_command with an array argument.",
                    :test_command_arg_false => "A test_command with a Boolean argument.",
                    :test_command_arg_hash => "A test_command with an Hash argument.",
                    :test_command_arg_named_arg => "A test_command with an arg named arg.",
                    :test_command_arg_timestamp => "A test_command with a Timestamp argument and an unnecessarily long description which should overflow when\nit tries to line up with other descriptions.",
                    :test_command_mixed_options => "A test_command with several mixed options.",
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

end
