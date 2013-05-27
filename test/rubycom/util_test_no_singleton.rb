require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"

class TestClassNoSingleton
  def test_method
    "TEST_INSTANCE_METHOD"
  end

  include Rubycom
end