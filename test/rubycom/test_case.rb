require 'time'

require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_module.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_composite.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_singleton.rb"

module UtilTestModuleRunner
  extend UtilTestModule
end
module UtilTestCompositeRunner
  extend UtilTestComposite
end
module UtilTestSingletonRunner
  extend UtilTestSingleton
end

require 'test/unit'
#noinspection RubyInstanceMethodNamingConvention
class TestCase < Test::Unit::TestCase
  def test_case
    base = UtilTestModule
    args = ["test_command_with_arg", "Hello World"]
    result = Rubycom.run(base,args)
    puts result
  end
end