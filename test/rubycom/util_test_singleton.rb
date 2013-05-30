require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_composite.rb"

module UtilTestSingleton
  def self.test_method
    "TEST_SINGLETON_METHOD"
  end

  include Rubycom
end