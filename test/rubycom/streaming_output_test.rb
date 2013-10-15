require "#{File.dirname(__FILE__)}/../../lib/rubycom/streaming_output.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class StreamingOutputTest < Test::Unit::TestCase

  def capture_out(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  def test_process_output
    test_result = 'test command output'

    result = capture_out { Rubycom::StreamingOutput.process_output(test_result) }

    expected = "test command output\n"
    assert_equal(expected, result)
  end

end
