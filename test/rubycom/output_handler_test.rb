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

  def test_process_output_hash
    c_in, c_out, c_err = Open3.popen3("ruby -e 'puts \"subprocess test command output\"'")
    result = {
        in: c_in,
        out: c_out,
        err: c_err
    }
    result = capture_out { Rubycom::OutputHandler.process_output(result) }

    expected = "subprocess test command output\n"
    assert_equal(expected, result)
  end

end
