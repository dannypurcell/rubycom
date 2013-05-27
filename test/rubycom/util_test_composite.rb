require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/test_rubycom.rb"

module UtilTestComposite

  include UtilTestClass

  # A test_command in a composite console
  #
  # @param [String] test_arg a test argument
  # @return [String] the test arg
  def self.test_composite_command(test_arg)
    test_arg
  end

  include Rubycom
end