require "#{File.dirname(__FILE__)}/../../lib/rubycom/output_handler.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class OutputHandlerTest < Test::Unit::TestCase

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

    result = capture_out { Rubycom::OutputHandler.process_output(test_result) }

    expected = "test command output\n"
    assert_equal(expected, result)
  end

  def test_process_output_empty
    test_result = ''

    result = capture_out { Rubycom::OutputHandler.process_output(test_result) }

    expected = "\n"
    assert_equal(expected, result)
  end

  def test_process_output_nil
    test_result = nil

    result = capture_out { Rubycom::OutputHandler.process_output(test_result) }

    expected = "\n"
    assert_equal(expected, result)
  end

  def test_process_output_object
    test_result = Object.new

    result = capture_out { Rubycom::OutputHandler.process_output(test_result) }

    expected = "--- !ruby/object {}\n"
    assert_equal(expected, result)
  end

  def test_process_output_array
    test_result = []

    result = capture_out { Rubycom::OutputHandler.process_output(test_result) }

    expected = "--- []\n"
    assert_equal(expected, result)
  end

  def test_process_output_hash
    test_result = {test: 'val'}

    result = capture_out { Rubycom::OutputHandler.process_output(test_result) }

    expected = "---\n:test: val\n"
    assert_equal(expected, result)
  end

end
