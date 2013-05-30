require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_module.rb"

module UtilTestComposite
  include UtilTestModule

  # A test_command in a composite console
  #
  # @param [String] test_arg a test argument
  # @return [String] the test arg
  def test_composite_command(test_arg)
    test_arg
  end

  include Rubycom
end