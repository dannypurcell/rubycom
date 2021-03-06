#!/usr/bin/env ruby
require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_module.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_no_singleton.rb"

# Composite module for testing
module UtilTestComposite
  include UtilTestModule

  include UtilTestNoSingleton

  require "#{File.expand_path(File.dirname(__FILE__))}/util_test_sub_module.rb"
  include UtilTestSubModule

  # A test_command in a composite console
  #
  # @param [String] test_arg a test argument
  # @return [String] the test arg
  def self.test_composite_command(test_arg)
    test_arg
  end

end
