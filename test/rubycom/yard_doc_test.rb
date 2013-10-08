require "#{File.dirname(__FILE__)}/../../lib/rubycom/sources.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class SourcesTest < Test::Unit::TestCase

  def test_source_commands
    test_commands =
    result = Rubycom::YardDoc.document_commands()
    expected =
    assert_equal(expected, result)
  end

end
