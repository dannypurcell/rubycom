require 'time'

require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_class.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_composite.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_no_singleton.rb"

require 'test/unit'
#noinspection RubyInstanceMethodNamingConvention
class TestCase < Test::Unit::TestCase
  def test
    base = UtilTestComposite
    args = ["help"]
    result = Rubycom.run(base, args)
    puts result
    #include UtilTestClass
  end
end